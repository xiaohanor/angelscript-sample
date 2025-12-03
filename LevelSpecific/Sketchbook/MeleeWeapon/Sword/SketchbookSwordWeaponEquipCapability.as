/**
 * Creates and attaches a static mesh to the player when activated.
 */
class USketchbookSwordEquipCapability : UHazePlayerCapability
{
    default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = Sketchbook::Melee::DebugCategory;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;
    
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Sketchbook::Melee::SketchbookMelee);

	default CapabilityTags.Add(BlockedWhileIn::Crouch);


    UFUNCTION(BlueprintOverride)
    void Setup()
    {
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        USketchbookSwordPlayerComponent::Get(Player).EquipWeapon();
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        USketchbookSwordPlayerComponent::Get(Player).UnequipWeapon();
    }
}