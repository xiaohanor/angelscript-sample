
/** A compound capability is like a parent capability, or a behaviour tree capability.
 * It works like a normal capability but you can expand it with 'HazeChildCapability'
 * 
*/
class UExampleCompoundCapability : UHazeCompoundCapability
{
	/** This function is what creates the child structure used by the compound capability
	* Each compound can contain other compounds or 'HazeChildCapability'
	*/
	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			.Add(UHazeCompoundSequence()
				.Then(UHazeCompoundSelector()
					.Try(UHazeCompoundStatePicker()
						.State(n"ExampleChildCapability")))
			);
	}

	// Here are all the compounds available to create
	// the tree structure of the child capabilities
	void AvailableCompounds()
	{
		/**
		* Executes all ChildCapabilities and Compound inside it every frame.
		* It is considered active if any of its children is active.
		*/
		UHazeCompoundRunAll()
		// Use the 'Add' keyword to add child capabilities to the 'RunAll'
		.Add(n"ExampleChildCapability")
		.Add(n"ExampleChildCapability")
		;


		/**
		* Executes each ChildCapability and Compound inside it in order.
		* It becomes active when the first child wants to activate.
		* When the first child deactivates, the second child is able to activate.
		*
		* If a child fails to activate when it should, the whole sequence fails,
		* making it start from the beginning the next frame.
		* It is considered active as long as the current child is active.
		*/
		UHazeCompoundSequence()
		// Use the 'Then' keyword to add child capabilities to the 'Sequence'
		.Then(n"ExampleChildCapability")
		.Then(n"ExampleChildCapability")
		;


		/**
		* Tries each ChildCapability and Compound inside it every frame until 
		* it finds one that wants to be active.
		* Once an active child is found, no further checks are done.
		*
		* On subsequent frames, each child is checked again from the start.
		* If an earlier child becomes active, any later children are reset.
		* It is considered active as long as the current child is active.
		*/
		UHazeCompoundSelector()
		// Use the 'Try' keyword to add child capabilities to the 'Selector'
		.Try(n"ExampleChildCapability")
		.Try(n"ExampleChildCapability")
		;


		/**
		* Tries to find a ChildCapability or Compound that wants to be active.
		* Once a child is active, that child continues to be the only one active until
		* it deactivates. No other child are checked until the current state finishes.
		*
		* On subsequent frames, it will only check the current active child.
		* Once a child finishes, all children are checked again from the beginning.
		* It is considered active as long as the current child is active.
		*/
		UHazeCompoundStatePicker()
		// Use the 'State' keyword to add child capabilities to the 'StatePicker'
		.State(n"ExampleChildCapability")
		.State(n"ExampleChildCapability")
		;
	}

}


class UExampleChildCapability : UHazeChildCapability
{
	// Can be used either locally or networked
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
}