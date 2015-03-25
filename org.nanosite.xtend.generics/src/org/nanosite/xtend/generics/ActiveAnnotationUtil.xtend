package org.nanosite.xtend.generics

import java.util.List
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import org.eclipse.xtend.lib.macro.expression.Expression
import org.eclipse.xtext.xbase.XExpression
import java.net.URLClassLoader
import java.net.URL
import java.util.regex.Pattern
import java.net.URLDecoder
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.ExecutableDeclaration
import java.util.ArrayList
import org.eclipse.xtend.core.xtend.XtendExecutable

class ActiveAnnotationUtil {
	private TransformationContext context

	new(TransformationContext context) {
		this.context = context
	}

	def void applyToBody(ExecutableDeclaration exec, String transformerClassName, List<String> methods,
		List<? extends List<?>> args) {
		val transformer = exec.getTransformer(transformerClassName)

		val expr = exec.getExpression(context)
		for (i : 0 ..< methods.size) {
			val curArgs = new ArrayList<Object>
			curArgs += expr
			curArgs += args.get(i)
			transformer.run(methods.get(i), curArgs)
		}
	}

	def Object getTransformer(ExecutableDeclaration exec, String transformerClassName) {
		val exprO = exec.getExpression(context)

		// this is the hackiest thing i've done in my life.
		// probably.
		// exprO is the body of the method, i.e. usually an XBlockExpression
		// but we cannot directly cast it to one
		// because if we load XBlockExpression or something similar here
		// it uses a different class loader 
		// and we get a ClassCastException.
		// So instead we construct a new classloader that has access 
		// to everything from this plugin except the transformer class, 
		// and also to the actual class of exprO and everything
		// its class loader can see
		var hloader = new HidingClassLoader(this.class.classLoader)
		hloader.hideClass(transformerClassName)
		hloader.hideClass("org.nanosite.xtend.generics.DebugException")
		val dloader = new DelegatingClassLoader(exprO.class.classLoader, hloader)
		val URL[] urls = newArrayOfSize(1)
		val container = getClassContainer(this.class)

		// and then another a child class loader which will reload the transformer class
		val url = new URL(container)
		urls.set(0, url)
		val loader = new URLClassLoader(urls, dloader)

		// then we create an instance of the transformer
		val transformerClass = loader.loadClass(transformerClassName)
		val transformer = transformerClass.declaredConstructors.get(0).newInstance(context)
		transformer
	}

	def void applyToClasses(List<? extends MutableClassDeclaration> classes, String transformerClassName,
		List<String> methods, List<? extends List<?>> args) {
		val func = classes.findFirst[!declaredMembers.filter(ExecutableDeclaration).empty]?.declaredMembers?.filter(
			ExecutableDeclaration)?.head
		if (func != null) {
			val transformer = func.getTransformer(transformerClassName)

			// and perform the transformation.
			// the transformer can just use all classes normally.
			for (clazz : classes) {
				for (method : clazz.declaredMembers.filter(ExecutableDeclaration)) {
					val expr = method.getExpression(context)
					for (i : 0 ..< methods.size) {
						val curArgs = new ArrayList<Object>
						curArgs += expr
						curArgs += clazz
						curArgs += args.get(i)
						transformer.run(methods.get(i), curArgs)
					}
				}
			}

		}
	}

	def List<XExpression> getExpressions(MutableMethodDeclaration method, extension TransformationContext context) {
		val Expression body = method.body
		val sourceElement = body.primarySourceElement // as org.eclipse.xtend.core.macro.declaration.ExpressionImpl
		val actualBlock = sourceElement.run("getDelegate")
		val exprs = actualBlock.run("getExpressions") as List<XExpression>
		exprs
	}

	def Object getExpression(ExecutableDeclaration method, extension TransformationContext context) {
		val Expression body = method.body
		val sourceElement = body.primarySourceElement // as org.eclipse.xtend.core.macro.declaration.ExpressionImpl
		val actualBlock = sourceElement.run("getDelegate")
		actualBlock
	}

	def protected run(Object instance, String methodName) {
		if (instance != null) {
			val objClass = instance.class
			val method = objClass.getMethod(methodName)
			method.invoke(instance)
		}
	}

	def protected run(Object instance, String methodName, List<? extends Object> args) {
		val objClass = instance.class
		val method = objClass.methods.findFirst[name == methodName && parameterTypes.size == args.size]
		method.invoke(instance, args.toArray)
	}

	/**
	 * We can't print to the console, so we throw an exception with our message :)
	 */
	def static void println(Object s) {
		throw new IllegalArgumentException(s.toString)
	}

	public def static String getClassContainer(Class<?> cl) {
		var c = cl
		if (c == null) {
			throw new NullPointerException("The Class passed to this method may not be null");
		}
		try {
			while (c.isMemberClass() || c.isAnonymousClass()) {
				c = c.getEnclosingClass(); //Get the actual enclosing file
			}
			if (c.getProtectionDomain().getCodeSource() == null) {

				//This is a proxy or other dynamically generated class, and has no physical container,
				//so just return null.
				return null;
			}
			var String packageRoot;
			try {

				//This is the full path to THIS file, but we need to get the package root.
				val String thisClass = c.getResource(c.getSimpleName() + ".class").toString();
				packageRoot = replaceLast(thisClass, Pattern.quote(c.getName().replaceAll("\\.", "/") + ".class"), "");
				if (packageRoot.endsWith("!/")) {
					packageRoot = replaceLast(packageRoot, "!/", "");
				}
			} catch (Exception e) {

				//Hmm, ok, try this then
				packageRoot = c.getProtectionDomain().getCodeSource().getLocation().toString();
			}
			packageRoot = URLDecoder.decode(packageRoot, "UTF-8");
			return packageRoot;
		} catch (Exception e) {
			throw new RuntimeException("While interrogating " + c.getName() + ", an unexpected exception was thrown.", e);
		}
	}

	def public static String replaceLast(String text, String regex, String replacement) {
		return text.replaceFirst("(?s)" + regex + "(?!.*?" + regex + ")", replacement);
	}
}
