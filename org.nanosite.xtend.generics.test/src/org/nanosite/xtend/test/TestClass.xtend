package org.nanosite.xtend.test

import org.nanosite.xtend.generics.Reified
import org.nanosite.xtend.generics.GenericConstructor
import java.util.List
import org.nanosite.xtend.generics.ReifiedAware

@Reified
@GenericConstructor(constructorParams=#[String],typeParam="T")
class TestClass<V, T> {
	def void whatever(){
		val Object o = "asd"
		 if (true){ 
		 	println("something") 
		 }else{
		 	println("bla")
		 }
	} 
	
	def static void main(String[] args){
		val tc = new TestClass<Integer, Integer>("smthing")
		tc.whatever
		println(tc.meAT)
		if (tc instanceof List){
			println("")
		}
		if (tc instanceof TestClass<Integer,String>){
			println("")
		}
	}
	 
	new(String s){
		println(s)
	} 
	
	def T getMeAT(){
		val t = new T("asd")
		if (t instanceof V)
			t
		else
			null
	}
	
	def dispatch doSomething(TestClass<String, Integer> tc){
		return 2;
	}
	
	def dispatch doSomething(TestClass<String, String> tc){
		return 5;
	}
}

@ReifiedAware 
class Something<V>{
	new (int i){
		val tc = new TestClass<Integer, Integer>("smthing")
		tc.whatever
	}
}