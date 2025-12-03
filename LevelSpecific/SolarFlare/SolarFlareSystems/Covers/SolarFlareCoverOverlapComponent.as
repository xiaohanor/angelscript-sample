event void FOnSolarFlarePlayerEnteredCover(AHazePlayerCharacter Player, USolarFlareCoverOverlapComponent Cover);
event void FOnSolarFlarePlayerLeftCover(AHazePlayerCharacter Player, USolarFlareCoverOverlapComponent Cover);

class USolarFlareCoverOverlapComponent : UBoxComponent
{
	default SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY()
	FOnSolarFlarePlayerEnteredCover OnSolarFlarePlayerEnteredCover;
	UPROPERTY()
	FOnSolarFlarePlayerLeftCover OnSolarFlarePlayerLeftCover;

	UPROPERTY(EditAnywhere)
	bool bShouldCrouch = false;

	UPROPERTY(EditAnywhere, Category = "Audio", Meta = (UIMin = 0.0, UIMax = 5000, ClampMin = 0.0, ClampMax = 5000, ForceUnits = "cm"))
	float AudioCoverAttenationMinDistance = 250;

	UPROPERTY(EditAnywhere, Category = "Audio", Meta = (UIMin = 0.0, UIMax = 5000, ClampMin = 0.0, ClampMax = 5000, ForceUnits = "cm"))
	float AudioCoverAttenationMaxDistance = 500;

	default LineThickness = 20.0;
	default ShapeColor = FColor::Cyan;

	TArray<FInstigator> Disablers; 
	TArray<USolarFlarePlayerComponent> UserComps;

	access CoverAudioManager = private, USolarFlarePlayerCoverAudioManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");
		OnComponentEndOverlap.AddUFunction(this, n"EndOverlap");	

		FVector OuterBoxExtents = GetScaledBoxExtent();
		OuterBoxExtents.X += AudioCoverAttenationMaxDistance;
		OuterBoxExtents.Y += AudioCoverAttenationMaxDistance;
		OuterBoxExtents.Z += AudioCoverAttenationMaxDistance;

		auto CoverVolumeActor = Cast<ASolarFlareCoverVolumeActor>(GetOwner());
		CoverVolumeActor.OuterBoxComp.SetWorldScale3D(FVector(1, 1, 1));
		CoverVolumeActor.OuterBoxComp.SetBoxExtent(OuterBoxExtents);

		CoverVolumeActor.OuterBoxComp.OnComponentBeginOverlap.AddUFunction(this, n"BeginOuterOverlap");
		CoverVolumeActor.OuterBoxComp.OnComponentEndOverlap.AddUFunction(this, n"EndOuterOverlap");
	}

	UFUNCTION()
	private void BeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		USolarFlarePlayerComponent UserComp = USolarFlarePlayerComponent::Get(OtherActor);

		if (UserComp != nullptr)
		{
			UserComps.AddUnique(UserComp);
			UserComp.AddCover(this);
			OnSolarFlarePlayerEnteredCover.Broadcast(UserComp.OwningPlayer, this);

			if (bShouldCrouch)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
				SetCrouching(Player);
			}
		}
	}

	UFUNCTION()
	private void BeginOuterOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		USolarFlarePlayerComponent UserComp = USolarFlarePlayerComponent::Get(OtherActor);	
		UserComp.OuterOverlapComps.Add(this);
	}
	
	UFUNCTION()
	private void EndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		USolarFlarePlayerComponent UserComp = USolarFlarePlayerComponent::Get(OtherActor);

		if (UserComp != nullptr)
		{
			UserComps.Remove(UserComp);
			UserComp.RemoveCover(this);
			OnSolarFlarePlayerLeftCover.Broadcast(UserComp.OwningPlayer, this);

			if (bShouldCrouch)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
				ClearCrouching(Player);
			}
		}
	}

	UFUNCTION()
	private void EndOuterOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		USolarFlarePlayerComponent UserComp = USolarFlarePlayerComponent::Get(OtherActor);
		UserComp.OuterOverlapComps.RemoveSingleSwap(this);
	}

	void SetCrouching(AHazePlayerCharacter Player)
	{
		if (!IsCoverEnabled())
			return;

		Player.ApplyCrouch(this);
	}

	void ClearCrouching(AHazePlayerCharacter Player)
	{
		Player.ClearCrouch(this);
		
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearSettingsByInstigator(this);
	}

	void AddDisabler(FInstigator Disabler)
	{
		Disablers.AddUnique(Disabler);
		SetCollisionEnabled(ECollisionEnabled::NoCollision);

		if (bShouldCrouch)
		{
			for (USolarFlarePlayerComponent Comp : UserComps)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Comp.Owner);
				ClearCrouching(Player);
			}
		}
	}

	void RemoveDisabler(FInstigator Disabler)
	{
		if (Disablers.Contains(Disabler))
			Disablers.Remove(Disabler);

		if (bShouldCrouch && Disablers.Num() == 0)
		{
			for (USolarFlarePlayerComponent Comp : UserComps)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Comp.Owner);
				SetCrouching(Player);
			}
		}

		if (IsCoverEnabled())
			SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	}

	bool HasDisabler(FInstigator Disabler)
	{
		return Disablers.Contains(Disabler);
	}

	bool IsCoverEnabled() const
	{ 
		return Disablers.Num() == 0;
	}

	bool IsCoveringPlayer() const
	{
		return UserComps.Num() > 0;
	}

	access:CoverAudioManager void GetCoverOverlapPlayerAudioAttenuationValues(AHazePlayerCharacter Player, float& OutOverlapValue)
	{	
		FVector OutPos;
		const float PlayerCoverVolumeDist = GetClosestPointOnCollision(Player.ActorCenterLocation, OutPos);
		const float PlayerAttenuationValue = Math::GetMappedRangeValueClamped(FVector2D(AudioCoverAttenationMinDistance, AudioCoverAttenationMaxDistance), FVector2D(0.0, 1.0), PlayerCoverVolumeDist);

		OutOverlapValue = PlayerAttenuationValue;		
	}
} 

#if EDITOR
class USolarFlareCoverOverlapComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USolarFlareCoverOverlapComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto CoverOverlapComp = Cast<USolarFlareCoverOverlapComponent>(Component);
		if (CoverOverlapComp == nullptr)
			return;

		// Audio attenuation
		FVector OuterBoxExtents;
		OuterBoxExtents.X = CoverOverlapComp.BoundsExtent.X + CoverOverlapComp.AudioCoverAttenationMaxDistance;
		OuterBoxExtents.Y = CoverOverlapComp.BoundsExtent.Y + CoverOverlapComp.AudioCoverAttenationMaxDistance;
		OuterBoxExtents.Z = CoverOverlapComp.BoundsExtent.Z + CoverOverlapComp.AudioCoverAttenationMaxDistance;

		// Draw outer box
		DrawWireBox(CoverOverlapComp.BoundsOrigin, OuterBoxExtents, CoverOverlapComp.ComponentQuat, FLinearColor(0.02, 0.94, 0.71), Thickness = 6.0);

		FVector RightFaceDrawPosOrigin = CoverOverlapComp.BoundsOrigin;
		RightFaceDrawPosOrigin.Y += CoverOverlapComp.BoundsExtent.Y;
		DrawArrow(RightFaceDrawPosOrigin, RightFaceDrawPosOrigin + (FVector::RightVector * CoverOverlapComp.AudioCoverAttenationMinDistance), FLinearColor(0.15, 0.68, 0.82), 50.0, 5.0);
		DrawArrow(RightFaceDrawPosOrigin, RightFaceDrawPosOrigin + (FVector::RightVector * CoverOverlapComp.AudioCoverAttenationMaxDistance), FLinearColor(0.14, 0.08, 0.80), 50.0, 5.0);

		FVector LeftFaceDrawPosOrigin = CoverOverlapComp.BoundsOrigin;
		LeftFaceDrawPosOrigin.Y -= CoverOverlapComp.BoundsExtent.Y;
		DrawArrow(LeftFaceDrawPosOrigin, LeftFaceDrawPosOrigin + (FVector::LeftVector * CoverOverlapComp.AudioCoverAttenationMinDistance), FLinearColor(0.15, 0.68, 0.82), 50.0, 5.0);
		DrawArrow(LeftFaceDrawPosOrigin, LeftFaceDrawPosOrigin + (FVector::LeftVector * CoverOverlapComp.AudioCoverAttenationMaxDistance), FLinearColor(0.14, 0.08, 0.80), 50.0, 5.0);

		FVector FrontFaceDrawPosOrigin = CoverOverlapComp.BoundsOrigin;
		FrontFaceDrawPosOrigin.X += CoverOverlapComp.BoundsExtent.X;
		DrawArrow(FrontFaceDrawPosOrigin, FrontFaceDrawPosOrigin + (FVector::ForwardVector * CoverOverlapComp.AudioCoverAttenationMinDistance), FLinearColor(0.15, 0.68, 0.82), 50.0, 5.0);
		DrawArrow(FrontFaceDrawPosOrigin, FrontFaceDrawPosOrigin + (FVector::ForwardVector * CoverOverlapComp.AudioCoverAttenationMaxDistance), FLinearColor(0.14, 0.08, 0.80), 50.0, 5.0);

		FVector BackFaceDrawPosOrigin = CoverOverlapComp.BoundsOrigin;
		BackFaceDrawPosOrigin.X -= CoverOverlapComp.BoundsExtent.X;

		DrawArrow(BackFaceDrawPosOrigin, BackFaceDrawPosOrigin + (FVector::BackwardVector * CoverOverlapComp.AudioCoverAttenationMinDistance), FLinearColor(0.15, 0.68, 0.82), 50.0, 5.0);
		DrawArrow(BackFaceDrawPosOrigin, BackFaceDrawPosOrigin + (FVector::BackwardVector * CoverOverlapComp.AudioCoverAttenationMaxDistance), FLinearColor(0.14, 0.08, 0.80), 50.0, 5.0);
	}
}
#endif