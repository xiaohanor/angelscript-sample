

event void FIslandNunchuckImpactResponseSignature(AHazePlayerCharacter ImpactInstigator, UIslandNunchuckImpactResponseComponent Component);


/**
 * A component used to detect impacts from the nunchuck
 * If placed under a primitive component, it will only trigger if the actor or that specific primitive is hit
*/
UCLASS(Meta = (HideCategories = "Rendering Physics Lod Cooking Activation Replication ComponentTick Collision"))
class UIslandNunchuckImpactResponseComponent : USceneComponent
{
	uint LastTriggerdFrameCount = 0;

	UPROPERTY(Category = "Melee")
	FIslandNunchuckImpactResponseSignature OnMeleeImpactEvent;

	bool ApplyImpact(AHazePlayerCharacter ImpactInstigator, FIslandNunchuckDamage Damage)
	{
		if(LastTriggerdFrameCount == Time::FrameNumber)
			return false;

		LastTriggerdFrameCount = Time::FrameNumber;
		OnMeleeImpact(ImpactInstigator);
		OnMeleeImpactEvent.Broadcast(ImpactInstigator, this);
		return true;
	}

	UFUNCTION(BlueprintEvent)
	protected void OnMeleeImpact(AHazePlayerCharacter ImpactInstigator)
	{
		
	}

	UPrimitiveComponent GetPrimitiveParentComponent() const
	{
		auto Prim = Cast<UPrimitiveComponent>(GetAttachParent());

		if(Prim == nullptr)
			Prim = UPrimitiveComponent::Get(Owner);

		return Prim;
	}
}

// /**
//  * A visualizer for the impact response component
//  */
// class UIslandNunchuckImpactResponseComponentVisualizer : UHazeScriptComponentVisualizer
// {
//     default VisualizedClass = UIslandNunchuckImpactResponseComponent;

//     UFUNCTION(BlueprintOverride)
//     void VisualizeComponent(const UActorComponent InComponent)
//     {
//         auto Component = Cast<UIslandNunchuckImpactResponseComponent>(InComponent);
		
// 		if(Component == nullptr || Component.GetOwner() == nullptr)
// 			return;

// 		if(Component.bUseParentPrimiteComponent)
// 		{
// 			auto Parent = Component.GetPrimitiveParentComponent();
// 			if(Parent != nullptr)
// 			{
// 				DrawWireShape(FHazeTraceShape::MakeFromComponent(Parent).Shape, Parent.GetShapeCenter(), Parent.GetComponentQuat());
// 			}
// 			else
// 			{
// 				FVector Origin, Bounds;
// 				Component.Owner.GetActorBounds(true, Origin, Bounds);
// 				float Size = Shape::GetEncapsulatingSphereRadius(FHazeTraceShape::MakeBox(Bounds).Shape);
// 				DrawWireStar(Origin, Size);
// 			}
// 		}	
// 		else if(Component.TriggerShape.Type != EHazeShapeType::None)
// 		{
// 			DrawWireShape(Component.TriggerShape.GetCollisionShape(), Component.GetWorldLocation(), Component.GetComponentQuat());
// 		}
//     }   
// } 