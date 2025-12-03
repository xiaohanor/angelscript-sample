event void FTundraGroundedLifeReceivingTargetableEventNoParams();

class UTundraGroundedLifeReceivingTargetableComponent : UTargetableComponent
{
	default TargetableCategory = n"Interaction";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(EditAnywhere, BlueprintHidden)
	bool bLerpTreeGuardianToPoint = false;

	UPROPERTY(EditAnywhere, BlueprintHidden, Meta = (EditCondition = "bLerpTreeGuardianToPoint", EditConditionHides))
	float TreeGuardianLerpDuration = 0.5;

	UPROPERTY(EditAnywhere, BlueprintHidden, Meta = (EditCondition = "bLerpTreeGuardianToPoint", EditConditionHides))
	FVector TreeGuardianLerpLocalOffset;

	UPROPERTY(EditAnywhere, BlueprintHidden, Meta = (EditCondition = "bLerpTreeGuardianToPoint", EditConditionHides))
	FVector TreeGuardianLerpMeshOffset;

	UPROPERTY()
	FTundraGroundedLifeReceivingTargetableEventNoParams OnCommitInteract;

	UPROPERTY()
	FTundraGroundedLifeReceivingTargetableEventNoParams OnStopInteract;

	UPROPERTY()
	FTundraGroundedLifeReceivingTargetableEventNoParams OnFoundTarget;

	UPROPERTY()
	FTundraGroundedLifeReceivingTargetableEventNoParams OnLostTarget;

	UPROPERTY(EditAnywhere)
	float MaxRange = 1000;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyTargetableRange(Query, MaxRange);
		return true;
	}
}

class UTundraGroundedLifeReceivingTargetableComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraGroundedLifeReceivingTargetableComponent;

	bool bSelected = false;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Targetable = Cast<UTundraGroundedLifeReceivingTargetableComponent>(Component);

		DrawWireSphere(Targetable.WorldLocation, Targetable.MaxRange, FLinearColor::Red);

		SetHitProxy(n"Targetable", EVisualizerCursor::Default);
		DrawPoint(Targetable.WorldLocation, bSelected ? FLinearColor::Green : FLinearColor::White, 50.0);
		DrawWorldString("Targetable", Targetable.WorldLocation, FLinearColor::Red);
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bSelected = false;
	}

	// Handle when the point with the hitproxy is clicked 
	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
							 EInputEvent Event)
	{
		if(HitProxy == n"Targetable")
		{
			bSelected = true;
			return true;
		}

		return false;
	}

	// Used by the editor to determine where the transform gizmo ends up
	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto Current = Cast<UTundraGroundedLifeReceivingTargetableComponent>(EditingComponent);

		if(bSelected)
		{
			OutLocation = Current.WorldLocation;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem,
										EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		if (!bSelected)
			return false;

		OutTransform = FTransform::MakeFromXZ(FVector::ForwardVector, FVector::UpVector);

		return true;
	}

	// Used by the editor when the transform gizmo is moved while we are overriding it
	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if(bSelected)
		{
			auto Current = Cast<UTundraGroundedLifeReceivingTargetableComponent>(EditingComponent);
			if (!DeltaTranslate.IsNearlyZero())
			{
				Current.WorldLocation += DeltaTranslate;
			}
			return true;
		}

		return false;
	}
}