package org.nanosite.xtend.generics

import java.util.ArrayList
import java.util.HashSet
import java.util.List
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference

class ReifiedAwareProcessor extends AbstractClassProcessor {
	override doTransform(List<? extends MutableClassDeclaration> annotatedClasses,
		extension TransformationContext context) {
		val extension util = new ActiveAnnotationUtil(context)

		for (c : annotatedClasses) {

			val methodGroups = c.declaredMethods.groupBy[simpleName.trimUnderscores]
			for (group : methodGroups.values.filter[size > 1].toList) {
				val dispatcher = group.sortBy[simpleName.length].head
				val others = group.filter[it !== dispatcher].toList

				val newFallbacks = new HashSet<List<Pair<String, String>>>
				for (o : others) {
					var suffix = ""
					for (param : o.parameters) {
						val annotation = (context.findTypeGlobally(param.type.type.qualifiedName) as TypeDeclaration).annotations.findFirst[
							annotationTypeDeclaration.qualifiedName == "org.nanosite.xtend.generics.Reified"]
						if (annotation != null && !param.type.actualTypeArguments.empty) {
							suffix += param.type.actualTypeArguments.map[simpleName].join
						}
					}
					if (suffix != "") {
						newFallbacks += o.parameters.map[simpleName -> type.type.qualifiedName].toList
						val newName = o.simpleName + suffix
						o.simpleName = newName
					}
				}
				val newMethods = new ArrayList
				for (fallback : newFallbacks) {
					newMethods += c.addMethod("_" + dispatcher.simpleName,
						[ newMethod |
							for (param : fallback)
								newMethod.addParameter(param.key, context.newTypeReference(param.value))
							newMethod.body = '''throw new UnsupportedOperationException();'''
							newMethod.returnType = others.head.returnType
						])
				}

				val comp = [TypeReference t1, TypeReference t2|t1.compare(t2)]
				others.sort(
					[MutableMethodDeclaration m1, MutableMethodDeclaration m2|
						comp.zipWith(m1.parameters.map[type].toList, m2.parameters.map[type].toList).reduce[p1, p2|
							if(p1 != 0) p1 else p2]])
				val allMethods = new ArrayList(others)
				allMethods += newMethods
				dispatcher.body = '''
					«FOR m : allMethods SEPARATOR " else "»
						if («FOR i : 0 ..< dispatcher.parameters.size SEPARATOR " && "»«context.getInstanceof(
						dispatcher.parameters.get(i).simpleName, m.parameters.get(i).type, !newMethods.contains(m))»«ENDFOR»){
							«IF !m.returnType.isVoid»return «ENDIF»«m.simpleName»(«FOR j : 0 ..< dispatcher.parameters.size SEPARATOR ", "»(«m.parameters.get(j).type.serialize»)«dispatcher.parameters.get(j).simpleName»«ENDFOR»);
						}
					«ENDFOR»
					else {
						throw new UnsupportedOperationException();
					}
				'''
			}
		}

		annotatedClasses.applyToClasses("org.nanosite.xtend.generics.GenericClassTransformer",
			#["addConstructorArgs", "replaceInstanceofParameterizedClass"], #[#[], #[]])
	}
	
	def protected String serialize(TypeReference type){
		'''«type.type.qualifiedName»«IF !type.actualTypeArguments.empty»<«FOR ta : type.actualTypeArguments SEPARATOR ", "»«ta.serialize»«ENDFOR»>«ENDIF»'''
	}

	def protected getInstanceof(TransformationContext context, String argName, TypeReference argType, boolean reified) {
		if (!reified) {
			'''«argName» instanceof «argType.type.qualifiedName»'''
		} else {
			'''«context.getXtendClassDeclarationString(argType)».isInstance(«argName»)'''
		}
	}

	def protected String getXtendClassDeclarationString(TransformationContext context, TypeReference type) {
		if ((context.findTypeGlobally(type.type.qualifiedName) as TypeDeclaration).annotations.exists[
			annotationTypeDeclaration.qualifiedName == "org.nanosite.xtend.generics.Reified"]) {
			'''new org.nanosite.xtend.generics.lib.XtendClassDescription(«type.type.qualifiedName».class, Arrays.asList(«FOR ta : type.
				actualTypeArguments SEPARATOR ", "»«context.getXtendClassDeclarationString(ta)»«ENDFOR»))'''
		} else {
			'''new org.nanosite.xtend.generics.lib.ClassicClassDescription(«type.type.qualifiedName».class)'''
		}
	}

	def protected int compare(TypeReference t1, TypeReference t2) {
		if (t1.isAssignableFrom(t2)) {
			if (t2.isAssignableFrom(t1)) {
				[TypeReference tp1, TypeReference tp2|compare(tp1, tp2)].zipWith(t1.actualTypeArguments,
					t2.actualTypeArguments).reduce[p1, p2|if(p1 != 0) p1 else p2]
			} else {
				-1
			}
		} else {
			if (t2.isAssignableFrom(t1)) {
				1
			} else {
				0
			}
		}
	}

	def protected <T1, T2, T3> List<T3> zipWith((T1, T2)=>T3 func, List<T1> t1s, List<T2> t2s) {
		if (t1s.size != t2s.size)
			throw new IllegalArgumentException()
		(0 ..< t2s.size).map[int i|func.apply(t1s.get(i), t2s.get(i))].toList
	}

	def protected String trimUnderscores(String in) {
		val char underscore = '_'
		for (i : 0 ..< in.length)
			if(in.charAt(i) != underscore) return in.substring(i)
		return ""
	}
	
	
}