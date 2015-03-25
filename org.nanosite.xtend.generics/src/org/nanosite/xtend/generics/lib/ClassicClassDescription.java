package org.nanosite.xtend.generics.lib;

/**
 * @author meilers - Initial contribution and API
 * @param <T> the class this description describes
 */
public class ClassicClassDescription<T> extends ClassDescription<T> {
	
	/**
	 * @param clazz the class for which a description should be created
	 * 
	 */
	public ClassicClassDescription(Class<T> clazz){
		this.javaClass = clazz;
	} 
	
	@Override
	public boolean equals(Object o){
		if (o instanceof ClassicClassDescription){
			ClassicClassDescription<?> cc = (ClassicClassDescription<?>) o;
			return cc.getJavaClass().equals(javaClass);
		}
		return false;
	}
	
	@Override
	public String toString() {
		return javaClass.getCanonicalName();
	}
	
	@Override
	public int hashCode() {
		return this.toString().hashCode();
	}

	@Override
	public boolean isInstance(Object o) {
		return javaClass.isInstance(o);
	}

	@Override
	public boolean isAssignableFrom(ClassDescription<?> other) {
		return javaClass.isAssignableFrom(other.getJavaClass());
	}
}
