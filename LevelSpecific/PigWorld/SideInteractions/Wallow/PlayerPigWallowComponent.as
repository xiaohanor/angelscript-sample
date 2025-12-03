struct FPigWallowAnimationData
{
	UPROPERTY()
	UAnimSequence Wallow1;

	UPROPERTY()
	UAnimSequence Wallow2;

	UAnimSequence GetRandomSequence() const
	{
		switch (Math::RandRange(0, 1))
		{
			case 0: return Wallow1;
			case 1: return Wallow2;
		}

		return nullptr;
	}
}

UCLASS(Abstract)
class UPlayerPigWallowComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	FTutorialPrompt TutorialPrompt;
	default TutorialPrompt.Action = ActionNames::Interaction;
	default TutorialPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
	default TutorialPrompt.MaximumDuration = 5.0;

	UPROPERTY(EditDefaultsOnly)
	FPigWallowAnimationData AnimationData;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> WallowCameraShakeClass;

	AHazePlayerCharacter PlayerOwner;

	TArray<APlayerBigWallowBoundsSpline> WallowBounds;

	float Height = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		TListedActors<APlayerBigWallowBoundsSpline> ListedWallowings;
		WallowBounds = ListedWallowings.GetArray();
	}

	UAnimSequence GetRandomWallowSequence() const
	{
		return AnimationData.GetRandomSequence();
	}

	void UpdateMudHeight(float DeltaTime)
	{
		FHazeTraceSettings Trace = Trace::InitFromPlayer(PlayerOwner);

		float NewHeight = 0;
		for (auto Overlap : Trace.QueryOverlaps(Owner.ActorLocation))
		{
			if (Overlap.Actor == nullptr)
				continue;

			if (Overlap.Actor.ActorHasTag(PigTags::Wallow))
			{
				NewHeight = (PlayerOwner.Mesh.GetSocketLocation(n"Spine2").Z - Overlap.Actor.GetActorLocation().Z);
				NewHeight = -(NewHeight - 180);
			}
		}
		Height = Math::Max(Height, NewHeight);
		Height = Math::Min(Height, 100);
		Height -= DeltaTime * 10.0;
		PlayerOwner.Mesh.SetScalarParameterValueOnMaterials(n"MudHeight", Height);
		
		UPlayerPigStretchyLegsComponent StretchyPigComponent = UPlayerPigStretchyLegsComponent::Get(PlayerOwner);
		if (StretchyPigComponent != nullptr)
		{
			if (StretchyPigComponent.SpringyMeshComponent != nullptr)
			{
				StretchyPigComponent.SpringyMeshComponent.SetScalarParameterValueOnMaterials(n"MudHeight", Height);
			}
		}
	}

	bool IsInWallowMud() const
	{
		const float HeightBias = 100.0;

		// bool bInsideSomeBounds = false;
		// for (APlayerBigWallowBoundsSpline WallowBound : WallowBounds)
		// {
		// 	float HeightDiff = Math::Abs(WallowBound.ActorLocation.Z - PlayerOwner.ActorLocation.Z);
		// 	if (HeightDiff > HeightBias)
		// 		continue;

		// 	if (WallowBound.ActorLocation.Dist2D(PlayerOwner.ActorLocation) > WallowBound.LongestRadius * 1.1) // cull
		// 		continue;

		// 	if (WallowBound.IsInsideBounds(PlayerOwner))
		// 	{
		// 		bInsideSomeBounds = true;
		// 		break;
		// 	}
		// }
		// if (bInsideSomeBounds)
		// 	return true;

		FVector TraceStart = PlayerOwner.ActorLocation + PlayerOwner.MovementWorldUp * HeightBias;
		FVector TraceEnd = TraceStart - PlayerOwner.MovementWorldUp * 100.0;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.UseLine();
		Trace.IgnorePlayers();

		FHitResult HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);
		if (HitResult.Actor != nullptr)
		{
			if (HitResult.Actor.ActorHasTag(PigTags::Wallow))
			{
				bool bInsideSomeBounds = false;
				for (APlayerBigWallowBoundsSpline WallowBound : WallowBounds)
				{
					if (WallowBound.ActorLocation.Dist2D(PlayerOwner.ActorLocation) > WallowBound.LongestRadius * 1.1) // cull
						continue;

					if (WallowBound.IsInsideBounds(PlayerOwner))
					{
						bInsideSomeBounds = true;
						break;
					}
				}
				if (bInsideSomeBounds)
					return true;
			}
		}

		return false;
	}
}