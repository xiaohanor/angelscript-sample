struct FTundraPlayerFairyTransformParams
{
	UPROPERTY()
	float MorphTime;
}

struct FTundraPlayerFairyMoveSplineEnterParams
{
	UPROPERTY()
	ATundraFairyMoveSpline MoveSpline = nullptr;

	FTundraPlayerFairyMoveSplineEnterParams(ATundraFairyMoveSpline InMoveSpline)
	{
		MoveSpline = InMoveSpline;
	}
}	

struct FTundraPlayerFairyLeapParams
{
	UPROPERTY()
	bool bLeapToRight;
}

UCLASS(Abstract)
class UTundraPlayerFairyEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, BlueprintReadOnly)
	ATundraPlayerFairyActor FairyActor;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FairyActor = Cast<ATundraPlayerFairyActor>(Owner);
		Player = FairyActor.Player;
	}

	// Called when we transform into the fairy
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTransformedInto(FTundraPlayerFairyTransformParams Params) {}

 	// Called when we transform back into human form
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTransformedOutOf(FTundraPlayerFairyTransformParams Params) {}

	// Called every time the fairy jumps from the ground
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJumped() {}

	// Called when the fairy starts a leap session, only called on the first leap, session ends when player gets grounded (when PlayerFairyLeapActiveCapability gets deactivated)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLeapSession() {}

	// Called every time the fairy leaps in the air (Fairy.OnLeaped) 
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeaped(FTundraPlayerFairyLeapParams Params) {}

	// Called when the fairy ends a leap session, called when the player gets grounded (when PlayerFairyLeapActiveCapability gets deactivated)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEndLeapSession() {}

	// Called when the fairy enters a move spline
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterMoveSpline(FTundraPlayerFairyMoveSplineEnterParams Params) {}

	// Called when the fairy enters a move spline
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExitMoveSpline() {}

	// Triggered when the fairy performs a ground dash
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundDash_Started() {}

	// Triggered when the fairy ground dash is finished or interrupted by something.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundDash_Stopped() {}

	// Only valid when the fairy is actually in a move spline.
	UFUNCTION(BlueprintPure)
	float GetMoveSplineAlpha() property
	{
		auto FairyComp = UTundraPlayerFairyComponent::Get(Owner);
		devCheck(FairyComp != nullptr, "Fairy comp was null in this case, this shouldn't happen");
		devCheck(FairyComp.CurrentMoveSpline != nullptr, "Current move spline is null, you shouldn't get move spline alpha while fairy isn't in move spline");
		return FairyComp.CurrentSplineDistance / FairyComp.CurrentMoveSpline.Spline.SplineLength;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepTrace_Plant(FPlayerFootstepParams Params) {}
}