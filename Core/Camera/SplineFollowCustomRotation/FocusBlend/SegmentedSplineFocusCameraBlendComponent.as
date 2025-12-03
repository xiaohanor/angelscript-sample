USTRUCT()
struct FSegmentedSplineFocusCameraBlendSettings
{
	UPROPERTY()
	float BlendIn = 0.5;

	UPROPERTY()
	float BlendOut = 0.5;
}

UCLASS(HideCategories = "Activation Navigation Hidden Rendering Cooking Input Actor LOD AssetUserData Debug Collision InternalHiddenObjects", Meta = (HighlightPlacement))
class USegmentedSplineFocusCameraBlendComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FSegmentedSplineFocusCameraBlendSettings FocusCameraBlendSettings;

	UPROPERTY(NotEditable)
	UHazeSplineComponent SplineComponent;

	access FocusBlendCapability = private, USplineFocusCameraBlendCapability;

	access : FocusBlendCapability TArray<UFocusCameraBlendSplineKey> SplineKeys;

	private TPerPlayer<bool> ActivePlayers;

	UPROPERTY(Transient, NotEditable, BlueprintHidden)
	ASplineFollowCustomRotationCameraActor FocusCamera = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Owner.GetComponentsByClass(SplineKeys);
		SplineKeys.Sort();
	}

	void ActivateForPlayer(ASplineFollowCustomRotationCameraActor FocusCameraActor, AHazePlayerCharacter Player, EHazeCameraPriority CameraPriority = EHazeCameraPriority::Low)
	{
		FocusCamera = FocusCameraActor;
		if (!devEnsure(FocusCamera != nullptr, "" + Name + " in " + Owner.Name + " needs a valid focus camera reference!"))
			return;

		ActivePlayers[Player] = true;
	}

	void DeactivateForPlayer(AHazePlayerCharacter Player)
	{
		ActivePlayers[Player] = false;
	}

	void GetBlendKeyInfoAtLocation(FVector Location, FFocusCameraBlendSplineKeyInfo& OutKeyInfo)
	{
		OutKeyInfo.PlayerDistanceAlongSpline = SplineComponent.GetClosestSplineDistanceToWorldLocation(Location);
		FindSplineKeyTupleAtDistanceAlongSpline(OutKeyInfo.PlayerDistanceAlongSpline, OutKeyInfo.PreviousKey, OutKeyInfo.NextKey);

		if (OutKeyInfo.PreviousKey == OutKeyInfo.NextKey)
		{
			// This means we haven't yet moved past the first key, fully blend it in
			OutKeyInfo.Alpha = 1.0;
		}
		else
		{
			float MinDistance = 0.0;
			if (OutKeyInfo.PreviousKey != nullptr)
				MinDistance = Math::Max(MinDistance, OutKeyInfo.PreviousKey.DistanceAlongSpline);

			float MaxDistance = SplineComponent.SplineLength;
			if (OutKeyInfo.NextKey != nullptr)
				MaxDistance = Math::Min(MaxDistance, OutKeyInfo.NextKey.DistanceAlongSpline);

			OutKeyInfo.Alpha = Math::Saturate(Math::NormalizeToRange(OutKeyInfo.PlayerDistanceAlongSpline, MinDistance, MaxDistance));
		}
	}

	void FindSplineKeyTupleAtDistanceAlongSpline(float DistanceAlongSpline, UFocusCameraBlendSplineKey& OutPreviousKey, UFocusCameraBlendSplineKey& OutNextKey)
	{
		if (SplineKeys.IsEmpty())
			return;

		// Could be optimized but mäh... not so bad
		for (int i = 0; i < SplineKeys.Num() - 1; i++)
		{
			UFocusCameraBlendSplineKey SplineKey = SplineKeys[i];
			if (SplineKey.DistanceAlongSpline < DistanceAlongSpline)
			{
				OutPreviousKey = SplineKey;
				OutNextKey = SplineKeys[i + 1];
			}
		}

		// Means we haven't reached first key yet...
		if (OutPreviousKey == nullptr)
		{
			OutPreviousKey = SplineKeys[0];
			OutNextKey = SplineKeys[0];
		}
	}

	UFUNCTION()
	bool IsFocusBlendActive() const
	{
		for (bool bActiveForPlayer : ActivePlayers)
		{
			if (bActiveForPlayer)
				return true;
		}

		return false;
	}

	UFUNCTION()
	bool IsFocusBlendActiveForPlayer(AHazePlayerCharacter Player) const
	{
		return ActivePlayers[Player];
	}

	UFUNCTION(CallInEditor, Category = "Spline Keys")
	void CreateSplineKey()
	{
		FocusCameraBlend::Editor_CreateSplineKey(Owner);
	}

#if EDITOR
	void RefreshSplineKeys()
	{
		SplineKeys.Empty();
		Owner.GetComponentsByClass(SplineKeys);
		SplineKeys.Sort();
	}
#endif
}