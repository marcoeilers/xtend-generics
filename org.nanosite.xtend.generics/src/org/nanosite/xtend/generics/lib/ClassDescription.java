package org.nanosite.xtend.generics.lib;

/**
 * @author meilers
 * @param <T> the class described by this description
 *
 */
public abstract class ClassDescription<T> {
	/**
	 * the described Java class
	 */
	protected Class<T> javaClass;
	
	/**
	 * @return the described Java class
	 * 
	 */
	public Class<T> getJavaClass(){
		return javaClass;
	}
	
	/**
	 * @param o the object to check if it is an instance of this class
	 * @return true if o is an instance of this class, false otherwise
	 * 
	 */
	public abstract boolean isInstance(Object o);
	
	/**
	 * Checks if this class is the same or a superclass of other
	 * @param other the other class
	 * @return true if this is the same or a superclass
	 */
	public abstract boolean isAssignableFrom(ClassDescription<?> other);
	
	public T newInstance(Class<?>[] params, Object... args){
		return RuntimeGenericsUtil.getInstance(javaClass, params, args);
	}
}
