package org.nanosite.xtend.generics

import org.eclipse.xtend.lib.macro.Active
import java.lang.annotation.Target
import java.lang.annotation.ElementType

@Target(ElementType.TYPE)
@Active(ReifiedProcessor)
annotation Reified {
	
}

@Target(ElementType.TYPE)
@Active(ReifiedProcessor)
annotation ReifiedAware {
	
}