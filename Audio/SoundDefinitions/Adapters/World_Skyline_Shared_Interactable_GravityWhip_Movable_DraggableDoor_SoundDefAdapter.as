
class UWorld_Skyline_Shared_Interactable_GravityWhip_Movable_DraggableDoor_SoundDefAdapter : USkylineDraggableDoorEventHandler
{

	UWorld_Skyline_Shared_Interactable_GravityWhip_Movable_SoundDef GetSoundDef() const property
	{
		return Cast<UWorld_Skyline_Shared_Interactable_GravityWhip_Movable_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	ASkylineDraggableDoor Door = nullptr;
	bool bDoorIsDraggable = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		Door = Cast<ASkylineDraggableDoor>(Owner);
		Door.InterfaceComp.OnActivated.AddUFunction(this, n"OnActivated");
	}

	UFUNCTION()
	bool ShouldActivateFromAdapter()
	{
		return bDoorIsDraggable;
	}

	UFUNCTION()
	bool ShouldDeactivateFromAdapter()
	{
		return false;
	}

	/*On Draggable Door Constraint Hit*/
	UFUNCTION(BlueprintOverride)
	void OnDraggableDoorConstraintHit()
	{
		FGravityWhipMovableParams Params;		
		Params.HitStrength = Door.TranslateComp.GetVelocity().Size();

		const float Alpha = Door.TranslateComp.GetCurrentAlphaBetweenConstraints().Size();
		
		if(Math::IsNearlyEqual(Alpha, 1, 0.1))
			SoundDef.ConstrainHitHighAlpha(Params);
		else if(Math::IsNearlyEqual(Alpha, 0, 0.1))
			SoundDef.ConstrainHitLowAlpha(Params);
	}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION()
	void OnActivated(AActor Caller)
	{
		bDoorIsDraggable = true;
	}

}