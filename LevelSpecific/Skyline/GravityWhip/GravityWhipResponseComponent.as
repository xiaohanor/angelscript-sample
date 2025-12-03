event void FGravityWhipGrabSignature(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents);
event void FGravityWhipReleaseSignature(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse);
event void FGravityWhipThrowSignature(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse);
event void FGravityWhipHitSignature(UGravityWhipUserComponent UserComponent, EHazeCardinalDirection HitDirection, EAnimHitPitch HitPitch, float HitWindowExtraPushback, float HitWindowPushbackMultiplier);
event void FGravityWhipSignature();
event void FOnGravityWhipGloryKill(UGravityWhipUserComponent UserComponent, FGravityWhipActiveGloryKill Sequence);

struct FGravityWhipResponseGrab
{
	UGravityWhipUserComponent UserComponent = nullptr;
	UGravityWhipTargetComponent TargetComponent = nullptr;
}

class UGravityWhipResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	/**
	 * Name of the category this object belongs to.
	 * NOTE: Can only multi-grab objects with matching category names.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	FName CategoryName = NAME_None;

	/**
	 * How the whip handles the object while grabbed.
	 * NOTE: Can only multi-grab objects with matching grab modes.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	EGravityWhipGrabMode GrabMode = EGravityWhipGrabMode::Drag;

	/**
	 * Whether this object can ever be grabbed together with other objects.
	 * Doesn't do anything in legacy mode.
	 * NOTE: If false, this object will have exclusivity if targeted, targeting another will always exclude this.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	bool bAllowMultiGrab = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response",  Meta = (EditCondition = "GrabMode == EGravityWhipGrabMode::Sling", EditConditionHides))
	float MinSpreadRadius = 200.0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response",  Meta = (EditCondition = "GrabMode == EGravityWhipGrabMode::Sling", EditConditionHides))
	float MaxSpreadRadius = 400.0;

	// Offset radius from origin in sling mode. 
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response",  Meta = (EditCondition = "GrabMode == EGravityWhipGrabMode::Sling", EditConditionHides))
	float OffsetRadius = 100.0;

	// Determines which axis we want to use as a "forward" when slinging the object.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response", Meta = (EditCondition = "GrabMode == EGravityWhipGrabMode::Sling", EditConditionHides))
	FVector ForwardAxis = FVector::ForwardVector;

	// While the object is grabbed by slinging, spin it in the air at this speed
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response", Meta = (EditCondition = "GrabMode == EGravityWhipGrabMode::Sling", EditConditionHides))
	FRotator SpinSpeedWhileSlinging;

	// WhipSlingAutoAims only apply when they share a category with the slingable
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response", Meta = (EditCondition = "GrabMode == EGravityWhipGrabMode::Sling", EditConditionHides))
	TArray<FName> SlingAutoAimCategories;
	default SlingAutoAimCategories.Add(n"Default");

	// Whether we want to dynamically calculate the offset distance, (probably) better for constrained objects.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response", Meta = (EditCondition = "GrabMode == EGravityWhipGrabMode::Drag || GrabMode == EGravityWhipGrabMode::ControlledDrag", EditConditionHides))
	bool bUseDynamicOffsetDistance = false;

	// Wanted offset distance from the player's aim direction.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response", Meta = (EditCondition = "!bUseDynamicOffsetDistance && (GrabMode == EGravityWhipGrabMode::Drag || GrabMode == EGravityWhipGrabMode::ControlledDrag)", EditConditionHides))
	float OffsetDistance = 1000.0;

	// Wanted offset distance from the player's aim direction while aim is 2D constrained.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response", Meta = (EditCondition = "!bUseDynamicOffsetDistance && (GrabMode == EGravityWhipGrabMode::Drag || GrabMode == EGravityWhipGrabMode::ControlledDrag)", EditConditionHides))
	float OffsetDistance2D = 400.0;

	// Low means more control, high means more drag.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response", Meta = (EditCondition = "GrabMode == EGravityWhipGrabMode::ControlledDrag", EditConditionHides))
	float ControlDragBlend = 0.5;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	float ForceMultiplier = 1.0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	float ImpulseMultiplier = 1.0;
	
	// Additional force multiplier applied on top of ForceMultiplier when the player is using a mouse cursor
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	float MouseCursorForceMultiplier = 1.0;

	// When using a mouse, treat ControlledDrag as Control
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	bool bMouseCursorTreatDragAsControl = false;

	UPROPERTY(EditAnywhere, AdvancedDisplay, BlueprintReadWrite, Category = "Response")
	bool bGrabAttachImmediately = false;

	UPROPERTY(EditAnywhere, AdvancedDisplay, BlueprintReadWrite, Category = "Response")
	bool bGrabRequiresButtonMash = false;

	UPROPERTY(EditAnywhere, AdvancedDisplay, BlueprintReadWrite, Category = "Response", Meta = (EditCondition = "bGrabRequiresButtonMash", EditConditionHides))
	FButtonMashSettings ButtonMashSettings;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityWhipGrabSignature OnGrabbed;
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityWhipReleaseSignature OnReleased;
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityWhipThrowSignature OnThrown;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	bool bCanGloryKill = false;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FOnGravityWhipGloryKill OnGloryKill;
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityWhipSignature OnGloryKillEnded;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityWhipSignature OnStartGrabSequence;
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityWhipSignature OnEndGrabSequence;

	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityWhipHitSignature OnHitByWhip;

	TArray<FGravityWhipResponseGrab> Grabs;
	
	// Location the whip wants the target to move towards, only valid when grabbed.
	FVector DesiredLocation;

	// Rotation the whip wants the target to rotate towards, only valid when grabbed.
	FRotator DesiredRotation;

	// Location traced towards the aim direction, either impact point or end of trace, only valid when grabbed.
	FVector AimLocation;

	void Grab(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		FGravityWhipResponseGrab GrabData;
		GrabData.UserComponent = UserComponent;
		GrabData.TargetComponent = TargetComponent;
		Grabs.Add(GrabData);

		OnGrabbed.Broadcast(UserComponent, TargetComponent, OtherComponents);
	}

	void Release(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		const FVector& Impulse)
	{
		for (int i = Grabs.Num() - 1; i >= 0; --i)
		{
			const auto& Grab = Grabs[i];
			if (Grab.UserComponent == UserComponent && 
				Grab.TargetComponent == TargetComponent)
				Grabs.RemoveAt(i);
		}
			
		OnReleased.Broadcast(UserComponent, TargetComponent, Impulse);
	}

	void Throw(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		const FHitResult& HitResult,
		const FVector& Impulse)
	{
		for (int i = Grabs.Num() - 1; i >= 0; --i)
		{
			const auto& Grab = Grabs[i];
			if (Grab.UserComponent == UserComponent && 
				Grab.TargetComponent == TargetComponent)
				Grabs.RemoveAt(i);
		}
			
		OnThrown.Broadcast(UserComponent, TargetComponent, HitResult, Impulse);
	}

	UFUNCTION(BlueprintPure)
	bool IsGrabbed() const
	{
		for (int i = Grabs.Num() - 1; i >= 0; --i)
		{
			const auto& Grab = Grabs[i];
			if (Grab.UserComponent != nullptr &&
				Grab.TargetComponent != nullptr)
				return true;
		}

		return false;
	}
}

#if EDITOR
class UGravityWhipResponseVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityWhipResponseComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto ResponseComp = Cast<UGravityWhipResponseComponent>(InComponent);
		if (ResponseComp == nullptr || ResponseComp.Owner == nullptr)
			return;

		const FVector ForwardAxis = ResponseComp.ForwardAxis.GetSafeNormal();
		DrawCircle(ResponseComp.Owner.ActorLocation, ResponseComp.OffsetRadius, FLinearColor::Yellow, 3.0, Normal = ForwardAxis);
	}
} 
#endif