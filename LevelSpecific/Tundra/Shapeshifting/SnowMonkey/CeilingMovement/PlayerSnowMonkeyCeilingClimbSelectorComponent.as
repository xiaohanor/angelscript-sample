
/** SnowMonkeyCeilingClimbSelectorComponent are used to select a specific primitive component to be targeted for ceiling climbs,
 * normally all colliding components on the actor are targeted. Just add this as a child to components you wish to target
 * (only this component's closest parent will be targeted)
 */
class UTundraPlayerSnowMonkeyCeilingClimbSelectorComponent : USceneComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Parent = Cast<UPrimitiveComponent>(AttachParent);
		auto CeilingComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Owner);
		devCheck(Parent != nullptr, f"A ceiling climb selector component is attached to a scene component (not a primtive) on actor with name {Parent.Owner.Name}");
		devCheck(CeilingComp != nullptr, f"A ceiling climb selector component is attached to an actor that does not have a ceiling climb component.");

		CeilingComp.AddClimbableComponent(Parent);
	}
}