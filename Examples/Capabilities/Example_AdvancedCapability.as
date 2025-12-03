// Capability Advanced Functionality Example
// See http://wiki.hazelight.se/Scripting/Capabilities/Misc-Functionality
// (Control+Click) on links to open

class UExampleAdvancedCapability : UHazeCapability
{
	/**
	 * Capabilities can tick in different tick groups depending on whether they are active or not.
	 * For example, this capability will tick in Movement (100) when active, and BeforeMovement (50) when deactivated.
	 * This is used to allow capabilities to pre-empt each other even if they are later in the normal tick order. 
	 */
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;
	default SeparateInactiveTick(EHazeTickGroup::BeforeMovement, 50);

	/**
	 * Whenever a capability activates, any other capabilities that are currently active
	 * and that have the specified capability tag will be deactivates before this one becomes active.
	 * 
	 * It is _NOT_ possible to interrupt a networked capability with a local capability's activation.
	 * Attempting this will cause an error message.
	 */
	default InterruptsCapabilities(CapabilityTags::GameplayAction);
};