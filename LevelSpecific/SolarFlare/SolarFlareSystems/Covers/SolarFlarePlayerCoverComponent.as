event void FOnPlayerEnteredCover();

class USolarFlarePlayerCoverComponent : USceneComponent
{
	FOnPlayerEnteredCover OnPlayerEnteredCover;

	UPROPERTY(EditAnywhere)
	float Distance = 300.0;

	UPROPERTY(VisibleInstanceOnly)
	FVector CoverAudioAttenuationOrigin;

	UPROPERTY(EditAnywhere, Category = "Audio", Meta = (UIMin = 0.0, UIMax = 5000, ClampMin = 0.0, ClampMax = 5000, ForceUnits = "cm"))
	float AudioCoverAttenuationMinDistance = 250;

	UPROPERTY(EditAnywhere, Category = "Audio", Meta = (UIMin = 0.0, UIMax = 5000, ClampMin = 0.0, ClampMax = 5000, ForceUnits = "cm"))
	float AudioCoverAttenuationMaxDistance = 500;
	
	UPROPERTY(EditAnywhere, Category = "Audio")
	bool bVerticalAttenuation = false;

	UPROPERTY(EditAnywhere, Category = "Audio", Meta = (UIMin = 0.0, UIMax = 5000, ClampMin = 0.0, ClampMax = 5000, ForceUnits = "cm", EditCondition = bVerticalAttenuation))
	float AudioCoverVerticalAttenuationMinDistance = 250;

	UPROPERTY(EditAnywhere, Category = "Audio", Meta = (UIMin = 0.0, UIMax = 5000, ClampMin = 0.0, ClampMax = 5000, ForceUnits = "cm", EditCondition = bVerticalAttenuation))
	float AudioCoverVerticalAttenuationMaxDistance = 500;

	TArray<FInstigator> Disablers;
	
	access CoverAudioManager = private, USolarFlarePlayerCoverAudioManager;

	private USolarFlarePlayerCoverAudioManager AudioManager;
	bool bRegisteredToAudioManager = false;

	void ActivateEnteredCover()
	{
		OnPlayerEnteredCover.Broadcast();
	}

	UFUNCTION()
	void AddDisabler(FInstigator Disabler)
	{
		if (!Disablers.Contains(Disabler))
			Disablers.AddUnique(Disabler);

		if(AudioManager != nullptr)
			AudioManager.UnRegisterCover(this);
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator Disabler)
	{
		if (Disablers.Contains(Disabler))
			Disablers.Remove(Disabler);

		if(IsCoverEnabled())
			AudioManager.RegisterCover(this);
	}

	bool IsCoverEnabled()
	{
		return Disablers.Num() == 0;
	}

	void Destroyed()
	{
		AudioManager.UnRegisterCover(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bRegisteredToAudioManager)
		{
			AudioManager = SolarFlarePlayerCover::GetAudioManager();
			if(AudioManager != nullptr)
			{
				AudioManager.RegisterCover(this);
				SetComponentTickEnabled(false);

				bRegisteredToAudioManager = true;
			}
		}
	}
	
	FVector GetAttenuationOriginLocation() const property
	{
		return WorldLocation + CoverAudioAttenuationOrigin;
	}

	private void SetAttenuationOriginLocation(FVector InLocation) property {}

	void SetAttenuationOriginLocationDelta(const FVector& InDeltaLocation) property
	{
		CoverAudioAttenuationOrigin += InDeltaLocation;
	}

	access:CoverAudioManager void GetPlayerCoverAudioAttenuationValues(TPerPlayer<float>& OutValues)
	{	
		const float MinDistSqrd = Math::Square(AudioCoverAttenuationMinDistance);
		const float MaxDistSqrd = Math::Square(AudioCoverAttenuationMaxDistance);

		for(auto Player : Game::GetPlayers())
		{		
			FVector AttenuationOriginPoint = AttenuationOriginLocation;
			FVector PlayerHorizontalPos = Player.ActorCenterLocation;				
			AttenuationOriginPoint.Z = PlayerHorizontalPos.Z;

			// Extend distance calulcations to track closest "forward" location behind cover
			FVector AttenuationDirectionExtentStart = AttenuationOriginPoint;
			FVector AttenuationDirectionExtentEnd = AttenuationDirectionExtentStart + (-FVector::ForwardVector * Distance);	

			FVector ClosestCoverForwardLocation = Math::ClosestPointOnLine(AttenuationDirectionExtentStart, AttenuationDirectionExtentEnd, Player.ActorCenterLocation);

			AttenuationOriginPoint.X = ClosestCoverForwardLocation.X;

			const float PlayerHorizontalAttenuationDistSqrd = PlayerHorizontalPos.DistSquared(AttenuationOriginPoint);
			float DistComparisonSqrd = PlayerHorizontalAttenuationDistSqrd;	

			if(bVerticalAttenuation)
			{
				const float PlayerVerticalPos = Player.ActorCenterLocation.Z;
				const float PlayerVerticalDistSqrd = Math::Square(Math::Abs(PlayerVerticalPos - AttenuationOriginLocation.Z));
				DistComparisonSqrd = Math::Max(PlayerHorizontalAttenuationDistSqrd, PlayerVerticalDistSqrd);
			}			

			// If fully out of range, we can bail
			if(DistComparisonSqrd > MaxDistSqrd)				
				continue;			

			const float PlayerAttenuationValue = Math::GetMappedRangeValueClamped(FVector2D(MinDistSqrd, MaxDistSqrd), FVector2D(0.0, 1.0), DistComparisonSqrd);
			OutValues[Player] = PlayerAttenuationValue;		
		}
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Audio")
	void SnapAttenuationRange()
	{
		auto MeshComp = UStaticMeshComponent::Get(Owner);
		if(MeshComp == nullptr)
			return;

		Modify();

		float AttnRange = AudioCoverAttenuationMaxDistance - AudioCoverAttenuationMinDistance;
		if(AttnRange < 0)
			AttnRange = 250;

		AudioCoverAttenuationMinDistance = MeshComp.BoundsRadius;
		AudioCoverAttenuationMaxDistance = AudioCoverAttenuationMinDistance + AttnRange;
	}
#endif
};

#if EDITOR
class USolarFlareCoverVisualComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USolarFlarePlayerCoverComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto PlayerCoverComp = Cast<USolarFlarePlayerCoverComponent>(Component);
		if (PlayerCoverComp == nullptr)
			return;

		// FVector Origin;
		// FVector BoxExtents;
		// PlayerCoverComp.Owner.GetActorBounds(false, Origin, BoxExtents);

		FVector Start = PlayerCoverComp.Owner.ActorLocation + FVector(0.0, 0.0, 2000.0);
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.IgnoreActor(PlayerCoverComp.Owner);
		TraceSettings.UseLine();

		FHitResult Hit = TraceSettings.QueryTraceSingle(Start, Start + FVector::UpVector * 5000.0);

		FVector DrawLoc = PlayerCoverComp.WorldLocation;// + FVector(0.0, 0.0, BoxExtents.Z / 2);//

		// if (Hit.bBlockingHit)
		// {
		// 	DrawLoc = Hit.ImpactPoint + FVector(0.0, 0.0, 200.0);
		// }

		DrawArrow(DrawLoc, DrawLoc + -FVector::ForwardVector * PlayerCoverComp.Distance, FLinearColor::Green, 50.0, 5.0);

		// Audio attenuation
		FVector AttenuationDrawLoc = PlayerCoverComp.AttenuationOriginLocation;
		DrawArrow(AttenuationDrawLoc, AttenuationDrawLoc + (FVector::RightVector * PlayerCoverComp.AudioCoverAttenuationMinDistance), FLinearColor(0.15, 0.68, 0.82), 50.0, 5.0);
		DrawArrow(AttenuationDrawLoc, AttenuationDrawLoc + (FVector::LeftVector * PlayerCoverComp.AudioCoverAttenuationMinDistance), FLinearColor(0.15, 0.68, 0.82), 50.0, 5.0);

		DrawArrow(AttenuationDrawLoc, AttenuationDrawLoc + (FVector::RightVector * PlayerCoverComp.AudioCoverAttenuationMaxDistance), FLinearColor(0.14, 0.08, 0.80), 50.0, 5.0);
		DrawArrow(AttenuationDrawLoc, AttenuationDrawLoc + (FVector::LeftVector * PlayerCoverComp.AudioCoverAttenuationMaxDistance), FLinearColor(0.14, 0.08, 0.80), 50.0, 5.0);

		if(PlayerCoverComp.bVerticalAttenuation)
		{
			DrawArrow(AttenuationDrawLoc, AttenuationDrawLoc + (FVector::UpVector * PlayerCoverComp.AudioCoverVerticalAttenuationMinDistance), FLinearColor(0.15, 0.68, 0.82), 50.0, 5.0);
			DrawArrow(AttenuationDrawLoc, AttenuationDrawLoc + (FVector::DownVector * PlayerCoverComp.AudioCoverVerticalAttenuationMinDistance), FLinearColor(0.15, 0.68, 0.82), 50.0, 5.0);

			DrawArrow(AttenuationDrawLoc, AttenuationDrawLoc + (FVector::UpVector * PlayerCoverComp.AudioCoverVerticalAttenuationMaxDistance), FLinearColor(0.14, 0.08, 0.80), 50.0, 5.0);
			DrawArrow(AttenuationDrawLoc, AttenuationDrawLoc + (FVector::DownVector * PlayerCoverComp.AudioCoverVerticalAttenuationMaxDistance), FLinearColor(0.14, 0.08, 0.80), 50.0, 5.0);
		}

		// Attenuation origin translation widget		
		SetRenderForeground(true);

		SetHitProxy(n"SelectAttenuationOriginLocation", EVisualizerCursor::CardinalCross);
		DrawWireSphere(PlayerCoverComp.AttenuationOriginLocation, 100.0, Color = FLinearColor::Yellow, Thickness = 2);
		ClearHitProxy();
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
							 EInputEvent Event)
	{
		auto Comp = Cast<USolarFlarePlayerCoverComponent>(EditingComponent);
        if (Comp == nullptr)
            return false;

		if(HitProxy.IsEqual(n"SelectAttenuationOriginLocation"))
		{
			//Editor::SelectComponent(Comp, bActivateVisualizer = true);
			return true;
		}	

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto Comp = Cast<USolarFlarePlayerCoverComponent>(EditingComponent);
        if (Comp == nullptr)
            return false;

		OutLocation = Comp.AttenuationOriginLocation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		auto Comp = Cast<USolarFlarePlayerCoverComponent>(EditingComponent);
        if (Comp == nullptr)
            return false;

		Comp.Modify();
		Comp.SetAttenuationOriginLocationDelta(DeltaTranslate);
		return true;
	}
}

class USolarFlarePlayerCoverVisualComponent : UHazeScriptDetailCustomization
{
	default DetailClass = USolarFlarePlayerCoverComponent;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		HideProperty(n"CoverAudioAttenuationOrigin");
	}

}
#endif
