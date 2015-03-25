package org.nanosite.xtend.generics

import java.util.List
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.nanosite.xtend.generics.lib.ClassDescription

class ReifiedProcessor extends ReifiedAwareProcessor {

	override doTransform(List<? extends MutableClassDeclaration> annotatedClasses,
		extension TransformationContext context) {
		val extension util = new ActiveAnnotationUtil(context)

		for (c : annotatedClasses) {

			for (tp : c.typeParameters) {
				c.addField("___" + tp.simpleName.toLowerCase,
					[ f |
						f.type = ClassDescription.newTypeReference(tp.newTypeReference)
						f.initializer = '''null'''
					])
			}

			if (c.declaredConstructors.empty) {
				c.addConstructor [ constr |
					for (tp : c.typeParameters) {
						constr.addParameter("___" + tp.simpleName.toLowerCase,
							ClassDescription.newTypeReference(tp.newTypeReference))
					}
					constr.body = '''
						«FOR tp : c.typeParameters»
							this.__«tp.simpleName.toLowerCase» = __«tp.simpleName.toLowerCase»
						«ENDFOR»
					'''
				]
			} else {
				for (constr : c.declaredConstructors) {
					for (tp : c.typeParameters) {
						constr.addParameter("__" + tp.simpleName.toLowerCase,
							ClassDescription.newTypeReference(tp.newTypeReference))
					}
					constr.applyToBody("org.nanosite.xtend.generics.GenericClassTransformer", #["addClassAssignments"],
						#[#[c.typeParameters.map["__" + simpleName.toLowerCase].toList]])
				}
			}
		}

		annotatedClasses.applyToClasses("org.nanosite.xtend.generics.GenericClassTransformer",
			#["replaceNewTypeParameter", "replaceInstanceofTypeParameter"], #[#[], #[]])
		super.doTransform(annotatedClasses, context)
	}

}
