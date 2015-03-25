package org.nanosite.xtend.generics.lib;

import java.lang.reflect.Constructor;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

/**
 * @author meilers - Initial contribution and API
 */
public class RuntimeGenericsUtil {
	
	/**
	 * @param clazz
	 *            the class for which to get the constructor
	 * @param args
	 *            the argument types of the constructor
	 * @return the specified constructor of class clazz
	 * 
	 */
	@SuppressWarnings("unchecked")
	public static <T> Constructor<T> getConstructor(Class<T> clazz, Class<?>... args) {
		Constructor<T> result;
		try {
			Constructor<?>[] constrs = clazz.getConstructors();
			List<Constructor<?>> validConstructors = getFittingConstructors(constrs, args);
			Collections.sort(validConstructors, new Comparator<Constructor<?>>() {

				public int compare(Constructor<?> arg0, Constructor<?> arg1) {
					// we assume they have the same no of args
					for (int i = 0; i < arg0.getParameterTypes().length; i++) {
						if (!arg0.equals(arg1)) {
							if (arg0.getParameterTypes()[i].isAssignableFrom(arg1.getParameterTypes()[i])) {
								// arg0 > arg1
								return 1;
							}else{
								return -1;
							}
						}
					}
					return 0;
				}

			});
			result = (Constructor<T>) validConstructors.get(0);
			return result;
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	private static List<Constructor<?>> getFittingConstructors(Constructor<?>[] constrs, Class<?>... args) {
		List<Constructor<?>> result = new ArrayList<Constructor<?>>();
		for (Constructor<?> c : constrs) {
			if (c.getParameterTypes().length == args.length) {
				boolean fits = true;
				for (int i = 0; i < args.length; i++) {
					if (!c.getParameterTypes()[i].isAssignableFrom(args[i])) {
						fits = false;
						break;
					}
				}
				if (fits) {
					result.add(c);
				}
			}
		}
		return result;
	}

	/**
	 * @param c
	 *            a constructor of class T
	 * @param args
	 *            the arguments to hand to the constructor
	 * @return a new instance of T
	 * 
	 */
	public static <T> T getInstance(Constructor<T> c, Object... args) {
		T result;
		try {
			result = c.newInstance(args);
			return result;
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}
	
	public static <T> T getInstance(Class<T> clazz, Class<?>[] params, Object... args){
		return getInstance(getConstructor(clazz, params), args);
	}
	
	public static <T> T getInstance0(Class<T> clazz){
		try{
			return clazz.newInstance();
		}catch(Exception e){
			throw new RuntimeException(e);
		}
	}
	
	public static <T, T1> T getInstance1(Class<T> clazz, Class<T1> clazz1, T1 t1){
		return getInstance(getConstructor(clazz, new Class<?>[]{clazz1}), t1);
	}
	
	public static <T, T1, T2> T getInstance2(Class<T> clazz, Class<T1> clazz1, Class<T2> clazz2, T1 t1, T2 t2){
		return getInstance(getConstructor(clazz, new Class<?>[]{clazz1, clazz2}), t1, t2);
	}
	
	public static <T, T1, T2, T3> T getInstance3(Class<T> clazz, Class<T1> clazz1, Class<T2> clazz2, Class<T3> clazz3, T1 t1, T2 t2, T3 t3){
		return getInstance(getConstructor(clazz, new Class<?>[]{clazz1, clazz2, clazz3}), t1, t2, t3);
	}
	
	public static <T, T1, T2, T3, T4> T getInstance4(Class<T> clazz, Class<T1> clazz1, Class<T2> clazz2, Class<T3> clazz3, Class<T4> clazz4, T1 t1, T2 t2, T3 t3, T4 t4){
		return getInstance(getConstructor(clazz, new Class<?>[]{clazz1, clazz2, clazz3, clazz4}), t1, t2, t3, t4);
	}
	
	public static <T, T1, T2, T3, T4, T5> T getInstance5(Class<T> clazz, Class<T1> clazz1, Class<T2> clazz2, Class<T3> clazz3, Class<T4> clazz4, Class<T5> clazz5, T1 t1, T2 t2, T3 t3, T4 t4, T5 t5){
		return getInstance(getConstructor(clazz, new Class<?>[]{clazz1, clazz2, clazz3, clazz4, clazz5}), t1, t2, t3, t4, t5);
	}
}
