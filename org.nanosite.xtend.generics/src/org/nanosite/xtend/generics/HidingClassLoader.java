package org.nanosite.xtend.generics;

import java.util.HashSet;
import java.util.Set;

public class HidingClassLoader extends ClassLoader {
	private Set<String> toHide = new HashSet<String>();
	
	public HidingClassLoader(ClassLoader parent){
		super(parent);
	}
	
	@Override
	public Class<?> loadClass(String name) throws ClassNotFoundException {
		for (String th : toHide){
			if (name.startsWith(th))
				throw new ClassNotFoundException();
		}
		
		return super.loadClass(name);
	}
	
	public void hideClass(String name){
		toHide.add(name);
	}
	
	public void hideClasses(Set<String> names){
		toHide.addAll(names);
	}
	
}
