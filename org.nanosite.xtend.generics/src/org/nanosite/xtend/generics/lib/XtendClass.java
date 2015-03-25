package org.nanosite.xtend.generics.lib;

/**
 * @author meilers
 * @param <T> the class which implements this interface
 *
 */
public interface XtendClass<T> {
	/**
	 * @return the description of the class
	 */
	public ClassDescription<T> getClassDescription();
}
