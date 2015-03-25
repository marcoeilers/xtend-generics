package org.nanosite.xtend.generics.lib;

import java.util.List;

/**
 * @author meilers - Initial contribution and API
 * @param <T> The class described by this description
 */
public class XtendClassDescription<T> extends ClassDescription<T> {
	private List<ClassDescription<?>> typeParams;
	
	/**
	 * @param clazz the main class
	 * @param typeParams a list of the type parameters
	 * 
	 */
	public XtendClassDescription(Class<T> clazz, List<ClassDescription<?>> typeParams){
		this.javaClass = clazz;
		this.typeParams = typeParams;
	}
	
	@Override
	public boolean equals(Object o){
		if (o instanceof XtendClassDescription){
			XtendClassDescription<?> xc = (XtendClassDescription<?>) o;
			if (javaClass.equals(xc.getJavaClass())){
				if (typeParams.size() != xc.getTypeParams().size())
					return false;
				for (int i = 0; i < typeParams.size(); i++){
					if (!typeParams.get(i).equals(xc.getTypeParams().get(i)))
						return false;
				}
				return true;
			}
		}
		return false;
	}
	
	/**
	 * @return a list containing all type parameters
	 * 
	 */
	public List<ClassDescription<?>> getTypeParams(){
		//TODO return immutable view
		return typeParams;
	}

	@Override
	public int hashCode() {
		return this.toString().hashCode();
	}
	
	@Override
	public String toString() {
		StringBuilder sb = new StringBuilder();
		sb.append(javaClass.getCanonicalName());
		if (!typeParams.isEmpty()){
			sb.append("<");
			for (int i = 0; i < typeParams.size(); i++){
				sb.append(typeParams.get(i).toString());
				if (i < typeParams.size() - 1)
					sb.append(", ");
			}
			sb.append(">");
		}
		return sb.toString();
	}

	@Override
	@SuppressWarnings("rawtypes")
	public boolean isInstance(Object o) {
		if (o instanceof XtendClass){
			XtendClass xc = (XtendClass) o;
			return isAssignableFrom(xc.getClassDescription());
		}else{
			return javaClass.isInstance(o);
		}
	}

	@SuppressWarnings("rawtypes")
	@Override
	public boolean isAssignableFrom(ClassDescription<?> other) {
		if (other instanceof XtendClassDescription){
			XtendClassDescription xc = (XtendClassDescription) other;
			if (javaClass.isAssignableFrom(xc.getJavaClass())){
				if (typeParams.size() == xc.getTypeParams().size()){
					for (int i = 0; i < typeParams.size(); i++){
						//TODO: no wildcards and upper bounds and therefore very restrictive right now. obviously.
						if (!typeParams.get(i).equals(xc.getTypeParams().get(i)))
							return false;
					}
					return true;
				}
			}
			return false;
		}else{
			return javaClass.isAssignableFrom(other.getJavaClass());
		}
	}
}
