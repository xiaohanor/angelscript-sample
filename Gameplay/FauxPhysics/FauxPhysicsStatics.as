
namespace FauxPhysics
{

void CollectPhysicsParents(TArray<UFauxPhysicsComponentBase>& OutArray, USceneComponent Current, bool bCurrentActorOnly = false)
{
	USceneComponent CheckComponent = Current;
	while (CheckComponent != nullptr)
	{
		auto PhysicsComp = Cast<UFauxPhysicsComponentBase>(CheckComponent);
		if (PhysicsComp != nullptr)
			OutArray.Add(PhysicsComp);

		CheckComponent = CheckComponent.AttachParent;
		if (bCurrentActorOnly)
		{
			if (CheckComponent == nullptr || CheckComponent.Owner != Current.Owner)
				break;
		}
	}
}

/* FORCE vs IMPULSE

 * FORCE: Is applied over time, IE multiple frames.
 	This is useful for stuff like gravity, wind, springs, friction, etc. that is
 	expected to be applied over some time.

 	Velocity will increase by 'units/second', using DeltaTime. This means you dont have to
 	take DeltaTime into account when calling the 'ApplyForce' functions. Just send in the size of the force.

 * IMPULSE: Is applied immediately, IE one frame.
 	This is useful when you want to give objects a "kick".
 	For example a jump, explosion, getting hit by a bullet, and impact with something else etc.

 	Velocity will increase by 'units' directly, not using DeltaTime. This means you shouldn't DeltaTime your
 	impulse vector! If you have to use DeltaTime, that probably means you're actually applying a Force.
 */

/* APPLYING AT LOCATIONS
 * For some physics components (mostly rotating ones), _where_ the force/impulse is applied matters.
 	For others, (translating for example), the location of the force/impulse doesn't matter.

 	So its up to each implementation which one to use! However, using the 'At' variations are generally good practice,
 	since then if we decide to att rotations they will work as expected.
 */

// These functions will apply an impulse/force to the Child, and then to all parents that child is attached to.
// So if the player lands on mesh, and you call this function, the force/impulse of the player will be propagated to every
// 	physics component that child is attached to (including other actors)
UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ApplyFauxForceToParents(USceneComponent Child, FVector Force, bool bSameActorOnly = false)
{
	USceneComponent CheckComponent = Child;
	while (CheckComponent != nullptr)
	{
		auto PhysicsComp = Cast<UFauxPhysicsComponentBase>(CheckComponent);
		if (PhysicsComp != nullptr)
			PhysicsComp.ApplyForce(PhysicsComp.WorldLocation, Force);

		CheckComponent = CheckComponent.AttachParent;
		if (bSameActorOnly && CheckComponent != nullptr && CheckComponent.Owner != Child.Owner)
			break;
	}
}
UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ApplyFauxForceToParentsAt(USceneComponent Child, FVector WorldLocation, FVector Force, bool bSameActorOnly = false)
{
	USceneComponent CheckComponent = Child;
	while (CheckComponent != nullptr)
	{
		auto PhysicsComp = Cast<UFauxPhysicsComponentBase>(CheckComponent);
		if (PhysicsComp != nullptr)
			PhysicsComp.ApplyForce(WorldLocation, Force);

		CheckComponent = CheckComponent.AttachParent;
		if (bSameActorOnly && CheckComponent != nullptr && CheckComponent.Owner != Child.Owner)
			break;
	}
}
UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ApplyFauxImpulseToParents(USceneComponent Child, FVector Impulse, bool bSameActorOnly = false)
{
	USceneComponent CheckComponent = Child;
	while (CheckComponent != nullptr)
	{
		auto PhysicsComp = Cast<UFauxPhysicsComponentBase>(CheckComponent);
		if (PhysicsComp != nullptr)
			PhysicsComp.ApplyImpulse(PhysicsComp.WorldLocation, Impulse);

		CheckComponent = CheckComponent.AttachParent;
		if (bSameActorOnly && CheckComponent != nullptr && CheckComponent.Owner != Child.Owner)
			break;
	}
}
UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ApplyFauxImpulseToParentsAt(USceneComponent Child, FVector WorldLocation, FVector Impulse, bool bSameActorOnly = false)
{
	USceneComponent CheckComponent = Child;
	while (CheckComponent != nullptr)
	{
		auto PhysicsComp = Cast<UFauxPhysicsComponentBase>(CheckComponent);
		if (PhysicsComp != nullptr)
			PhysicsComp.ApplyImpulse(WorldLocation, Impulse);

		CheckComponent = CheckComponent.AttachParent;
		if (bSameActorOnly && CheckComponent != nullptr && CheckComponent.Owner != Child.Owner)
			break;
	}
}
UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ApplyFauxMovementToParents(USceneComponent Child, FVector Movement, bool bSameActorOnly = false)
{
	USceneComponent CheckComponent = Child;
	while (CheckComponent != nullptr)
	{
		auto PhysicsComp = Cast<UFauxPhysicsComponentBase>(CheckComponent);
		if (PhysicsComp != nullptr)
			PhysicsComp.ApplyMovement(PhysicsComp.WorldLocation, Movement);

		CheckComponent = CheckComponent.AttachParent;
		if (bSameActorOnly && CheckComponent != nullptr && CheckComponent.Owner != Child.Owner)
			break;
	}
}
UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ApplyFauxMovementToParentsAt(USceneComponent Child, FVector WorldLocation, FVector Movement, bool bSameActorOnly = false)
{
	USceneComponent CheckComponent = Child;
	while (CheckComponent != nullptr)
	{
		auto PhysicsComp = Cast<UFauxPhysicsComponentBase>(CheckComponent);
		if (PhysicsComp != nullptr)
			PhysicsComp.ApplyMovement(WorldLocation, Movement);

		CheckComponent = CheckComponent.AttachParent;
		if (bSameActorOnly && CheckComponent != nullptr && CheckComponent.Owner != Child.Owner)
			break;
	}
}

// These functions will apply an impulse/force to every component on the actor.
// The easy way to get some physics up and running!
UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ApplyFauxForceToActor(AActor Actor, FVector Force)
{
	TArray<UFauxPhysicsComponentBase> Components;
	Actor.GetComponentsByClass(Components);

	for(auto PhysicsComp : Components)
		PhysicsComp.ApplyForce(PhysicsComp.WorldLocation, Force);
}
UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ApplyFauxForceToActorAt(AActor Actor, FVector WorldLocation, FVector Force)
{
	TArray<UFauxPhysicsComponentBase> Components;
	Actor.GetComponentsByClass(Components);

	for(auto PhysicsComp : Components)
		PhysicsComp.ApplyForce(WorldLocation, Force);
}
UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ApplyFauxImpulseToActor(AActor Actor, FVector Impulse)
{
	TArray<UFauxPhysicsComponentBase> Components;
	Actor.GetComponentsByClass(Components);

	for(auto PhysicsComp : Components)
		PhysicsComp.ApplyImpulse(PhysicsComp.WorldLocation, Impulse);
}
UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ApplyFauxImpulseToActorAt(AActor Actor, FVector WorldLocation, FVector Impulse)
{
	TArray<UFauxPhysicsComponentBase> Components;
	Actor.GetComponentsByClass(Components);

	for(auto PhysicsComp : Components)
		PhysicsComp.ApplyImpulse(WorldLocation, Impulse);
}
UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ApplyFauxMovementToActor(AActor Actor, FVector Movement)
{
	TArray<UFauxPhysicsComponentBase> Components;
	Actor.GetComponentsByClass(Components);

	for(auto PhysicsComp : Components)
		PhysicsComp.ApplyMovement(PhysicsComp.WorldLocation, Movement);
}
UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ApplyFauxMovementToActorAt(AActor Actor, FVector WorldLocation, FVector Movement)
{
	TArray<UFauxPhysicsComponentBase> Components;
	Actor.GetComponentsByClass(Components);

	for(auto PhysicsComp : Components)
		PhysicsComp.ApplyMovement(WorldLocation, Movement);
}

UFUNCTION(Category = FauxPhysics, BlueprintCallable)
void ResetFauxPhysicsInternalState(AActor Actor)
{
	TArray<UFauxPhysicsComponentBase> Components;
	Actor.GetComponentsByClass(Components);

	for(auto PhysicsComp : Components)
		PhysicsComp.ResetInternalState();

	TArray<UFauxPhysicsWeightComponent> WeightComponents;
	Actor.GetComponentsByClass(WeightComponents);

	for(auto WeightComp : WeightComponents)
		WeightComp.ResetInternalState();
}

}