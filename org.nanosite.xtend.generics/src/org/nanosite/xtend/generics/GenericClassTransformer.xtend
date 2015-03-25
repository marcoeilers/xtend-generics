package org.nanosite.xtend.generics

import java.util.ArrayList
import java.util.Arrays
import java.util.List
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtext.common.types.JvmDeclaredType
import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtext.common.types.JvmParameterizedTypeReference
import org.eclipse.xtext.common.types.JvmTypeParameter
import org.eclipse.xtext.common.types.JvmTypeReference
import org.eclipse.xtext.common.types.TypesFactory
import org.eclipse.xtext.common.types.util.TypeReferences
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.validation.EObjectDiagnosticImpl
import org.eclipse.xtext.xbase.XBlockExpression
import org.eclipse.xtext.xbase.XConstructorCall
import org.eclipse.xtext.xbase.XExpression
import org.eclipse.xtext.xbase.XInstanceOfExpression
import org.eclipse.xtext.xbase.XbaseFactory
import org.nanosite.xtend.generics.lib.XtendClassDescription

class GenericClassTransformer {

	protected TransformationContext context

	new(TransformationContext context) {
		this.context = context
	}

	def <T extends XExpression> void replaceAll(Object exprO, Class<T> clazz, (T)=>boolean predicate,
		(T)=>XExpression transformer) {
		if (exprO != null) {
			val expr = exprO as XExpression
			val elements = expr.eAllContents.filter(clazz).filter(predicate).toIterable
			for (e : elements) {
				e.replace(transformer.apply(e))
			}

		}
	}

	def <T extends XExpression> void applyToAll(Object exprO, Class<T> clazz, (T)=>boolean predicate,
		(T)=>void transformer) {
		if (exprO != null) {
			val expr = exprO as XExpression
			val elements = expr.eAllContents.filter(clazz).filter(predicate).toIterable
			for (e : elements) {
				transformer.apply(e)
			}
		}
	}

	def void replaceInstanceofTypeParameter(Object exprO, MutableTypeDeclaration type) {
		replaceAll(exprO, XInstanceOfExpression,
			[ xio |
				xio.type.type instanceof JvmTypeParameter
			],
			[ xio |
				val errors = xio.eResource.errors.filter[
					message.startsWith(
						"Cannot perform instanceof check against type parameter " +
							(xio.type.type as JvmTypeParameter).name)].toList
				val result = XbaseFactory.eINSTANCE.createXFeatureCall => [
					feature = TypesFactory.eINSTANCE.createJvmOperation => [
						simpleName = "___" + (xio.type.type as JvmTypeParameter).name.toLowerCase + ".isInstance"
						val refs = type.compilationUnit.class.getDeclaredMethod("getTypeReferences").invoke(
							type.compilationUnit) as TypeReferences
						it.returnType = refs.getTypeForName("boolean", xio)
					]
					actualArguments += xio.expression
				]
				xio.eResource.errors.removeAll(errors)
				result
			])
	}

	def void replaceInstanceofParameterizedClass(Object exprO, MutableTypeDeclaration type) {
		replaceAll(exprO, XInstanceOfExpression,
			[ xio |
				xio.type.type instanceof JvmGenericType && 
				{
				val annotations = (xio.type.type as JvmGenericType).annotations
				annotations.exists[annotation.qualifiedName == "org.nanosite.xtend.generics.Reified"]
				}
			],
			[ xio |
				val refs = type.compilationUnit.class.getDeclaredMethod("getTypeReferences").invoke(type.compilationUnit) as TypeReferences
				XbaseFactory.eINSTANCE.createXMemberFeatureCall => [
					feature = (refs.findDeclaredType(XtendClassDescription, xio) as JvmDeclaredType).declaredOperations.
						findFirst[simpleName == "isInstance"]
					actualArguments += xio.expression
					memberCallTarget = refs.getClassDescription(xio.type)
				]
			])
	}

	def XExpression getClassDescription(TypeReferences refs, JvmTypeReference type) {
		XbaseFactory.eINSTANCE.createXConstructorCall => [
			constructor = (refs.findDeclaredType(XtendClassDescription, type) as JvmDeclaredType).declaredConstructors.
				head
			arguments += XbaseFactory.eINSTANCE.createXTypeLiteral => [
				it.type = type.type
			]
			arguments += XbaseFactory.eINSTANCE.createXFeatureCall => [ xfc |
				xfc.feature = (refs.findDeclaredType(Arrays, type) as JvmDeclaredType).declaredOperations.findFirst[
					simpleName == "asList"]
				if (type instanceof JvmParameterizedTypeReference){
					for (arg : type.arguments){
						xfc.actualArguments += getClassDescription(refs, arg)
					}
				}
			]
		]
	}

		def void replaceNewTypeParameter(Object exprO, MutableTypeDeclaration type) {
			replaceAll(exprO, XConstructorCall,
				[ XConstructorCall xcc |
					xcc.constructor != null && xcc.constructor.eIsProxy
				],
				[ XConstructorCall xcc |
					// resolve type to add error
					xcc.constructor
					val errs = xcc.eResource.errors.filter[message.startsWith("Cannot instantiate the type parameter ")]
					val node = NodeModelUtils.findActualNodeFor(xcc)
					val actualErrs = errs.filter[line == node.startLine]
					if (actualErrs.empty) {
						xcc
					} else {
						val typeArgName = actualErrs.head.message.substring(38)

						val paramAnnotation = type.annotations.findFirst[
							annotationTypeDeclaration.qualifiedName == "org.nanosite.xtend.generics.GenericConstructor" &&
								getStringValue("typeParam") == typeArgName]

						if (paramAnnotation != null) {

							val result = XbaseFactory.eINSTANCE.createXFeatureCall => [
								feature = TypesFactory.eINSTANCE.createJvmOperation => [
									simpleName = '''(«typeArgName»)org.nanosite.xtend.generics.lib.RuntimeGenericsUtil.getInstance«xcc.
										arguments.size»'''
								]
								it.actualArguments += XbaseFactory.eINSTANCE.createXFeatureCall => [
									feature = TypesFactory.eINSTANCE.createJvmField => [
										simpleName = '''___«typeArgName.toLowerCase».getJavaClass()'''
									]
								]
								for (c : paramAnnotation.getClassArrayValue("constructorParams")) {
									actualArguments += XbaseFactory.eINSTANCE.createXTypeLiteral => [
										type = TypesFactory.eINSTANCE.createJvmGenericType => [
											val nameParts = c.name.split("\\.")
											it.packageName = nameParts.subList(0, nameParts.length - 1).join(".")
											it.simpleName = c.simpleName
										]
									]
								}
								actualArguments += xcc.arguments
							]
							xcc.eResource.errors.removeAll(actualErrs)
							result
						} else {
							xcc
						}

					}
				])
		}

		def addConstructorArgs(Object exprO, MutableTypeDeclaration type) {
			exprO.replaceAll(XConstructorCall,
				[ cc |
					cc?.constructor?.declaringType?.annotations?.exists[
						annotation.qualifiedName == "org.nanosite.xtend.generics.Reified"]
				],
				[ cc |
					val result = XbaseFactory.eINSTANCE.createXConstructorCall
					result.constructor = cc.constructor
					result.arguments += cc.arguments
					//			cc.arguments += XbaseFactory.eINSTANCE.createXBooleanLiteral
					result.typeArguments += cc.typeArguments
					for (ta : result.typeArguments) {
						result.arguments += XbaseFactory.eINSTANCE.createXFeatureCall => [
							feature = TypesFactory.eINSTANCE.createJvmField => [
								simpleName = '''new org.nanosite.xtend.generics.lib.XtendClassDescription(«ta.simpleName».class, java.util.Arrays.asList())'''
							]
						]

					//					result.arguments += XbaseFactory.eINSTANCE.createXTypeLiteral => [
					//						it.type = ta.type
					//					]
					}
					result
				])

			if (exprO != null) {
				val expr = exprO as XExpression

				for (r : expr.eResource.resourceSet.resources) {
					val toRemove = new ArrayList
					for (e : r.errors) {
						if (e.message.startsWith('''Invalid number''')) {
							if (e instanceof EObjectDiagnosticImpl) {
								toRemove += e
							}
						}
					}

					r.errors.removeAll(toRemove)

				}
			}
		}

		def addClassAssignments(Object exprO, List<String> attributes) {
			val expr = exprO as XExpression

			if (expr instanceof XBlockExpression) {
				for (i : 0 ..< attributes.size)
					expr.expressions.add(0,
						{
							val assg = XbaseFactory.eINSTANCE.createXAssignment
							assg.feature = TypesFactory.eINSTANCE.createJvmField => [
								simpleName = "_" + attributes.get(i)
							]
							assg.value = XbaseFactory.eINSTANCE.createXFeatureCall => [
								feature = TypesFactory.eINSTANCE.createJvmField => [
									simpleName = attributes.get(i)
								]
							]
							assg
						})
			}
		}

		def replace(XExpression old, XExpression replacement) {
			EcoreUtil.replace(old, replacement)
		}

		def removeError(TransformationContext ctx, String err) {
			val support = ctx.class.declaredMethods.findFirst[name == "getProblemSupport"].invoke(ctx)

		}
	}
	