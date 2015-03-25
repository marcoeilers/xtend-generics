package org.nanosite.xtend.generics;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;

public class DebugException extends IllegalStateException {
	public DebugException(EObject eo){
		super(eo.toString());
	}
	
	private static String createMessage(EObject eo){
		StringBuilder sb = new StringBuilder();
		sb.append(eo.eClass().getName() + " " + eo.toString() + "\n");
		for (EStructuralFeature feature  : eo.eClass().getEAllStructuralFeatures()){
			if (eo.eIsSet(feature)){
				sb.append(feature.getName());
				sb.append(": ");
				sb.append(eo.eGet(feature).toString());
				sb.append("\n");
			}
		}
		return sb.toString();
	}
}
