
class UWorld_Skyline_Shared_Interactable_GravityWhip_Movable_BigDoor_SoundDefAdapter : USkylineDraggableDoorEventHandler
{

	UWorld_Skyline_Shared_Interactable_GravityWhip_Movable_SoundDef GetSoundDef() const property
	{
		return Cast<UWorld_Skyline_Shared_Interactable_GravityWhip_Movable_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Draggable Door Constraint Hit*/
	UFUNCTION(BlueprintOverride)
	void OnDraggableDoorConstraintHit()
	{
		//SoundDef.();
	}

	/*On Door Draggable*/
	UFUNCTION(BlueprintOverride)
	void OnDoorDraggable()
	{
		//SoundDef.();
	}

	/* END OF AUTO-GENERATED CODE */

	UFauxPhysicsTranslateComponent TranslateComp; 

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TranslateComp = UFauxPhysicsTranslateComponent::Get(Owner);
		TranslateComp.OnConstraintHit.AddUFunction(this, n"OnConstraintHit");
	}

	UFUNCTION()
	void OnConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		const float TranslationAlpha = TranslateComp.GetCurrentAlphaBetweenConstraints().Size();
		FGravityWhipMovableParams Params;
		Params.HitStrength = HitStrength;

		if(Math::IsNearlyEqual(TranslationAlpha, 0.0, 0.1))
		{
			SoundDef.ConstrainHitLowAlpha(Params);
		}
		else if(Math::IsNearlyEqual(TranslationAlpha, 1.0, 0.1))
		{
			SoundDef.ConstrainHitHighAlpha(Params);
		}
	}

}