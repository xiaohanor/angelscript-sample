class UBombTossPlatformLayoutsDataAsset : UDataAsset
{
	UPROPERTY()
	TMap<FString, FBombTossPlatformPositionLayouts> Layouts;
}

class UBombTossPlatformLightLayoutsDataAsset : UDataAsset
{
	UPROPERTY()
	TMap<FString, FBombTossPlatformLightFormationLayouts> Layouts;
}

class UBombTossPlatformPositionsValuesDataAsset : UDataAsset
{
	UPROPERTY(EditAnywhere)
	TArray<FBombTossPlatformPositionValues> PositionValues;
}

class UBombTossPlatformPatternsDataAsset : UDataAsset
{
	UPROPERTY(EditAnywhere)
	TMap<FString, FBombTossPlatformPattern> Patterns;
}

UCLASS(Abstract)
class AGameShowArenaPlatformManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	// default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaPlatformManagerMovingCapability");

	UPROPERTY(DefaultComponent)
	UGameShowArenaPlatformManagerEditorComponent EditorComp;

	// UPROPERTY(VisibleAnywhere)
	// TMap<FGuid, ABombToss_Platform> AllPlatformsByGuid;

	UPROPERTY(VisibleAnywhere)
	TMap<FGuid, AGameShowArenaPlatformArm> AllArmsByGuid;

	UPROPERTY(EditAnywhere)
	UBombTossPlatformPositionsValuesDataAsset PlatformPositionValuesDataAsset;

	UPROPERTY(EditAnywhere)
	UBombTossPlatformLayoutsDataAsset PlatformLayoutsDataAsset;

	bool bIsMovingPlatforms = false;
	float PlatformMoveDuration = 0;
	FString NewLayoutName;

	private EBombTossChallenges CurrentChallenge;

#if EDITOR
	UFUNCTION(CallInEditor)
	void EditorMapGuidsToPlatforms()
	{
		for (auto Platform : GetPlatformsSortedY())
		{
			Platform.PlatformGuid = Platform.ActorGuid;
		}
	}
	UFUNCTION(CallInEditor)
	void RemoveInvalidGUIDsFromAssets()
	{
		FGuid InvalidKey = FGuid(0, 0, 0, 0);
		for (auto Layout : PlatformLayoutsDataAsset.Layouts)
		{
			if (Layout.Value.ArmMoveDataByGuid.Contains(InvalidKey))
			{
				Layout.Value.ArmMoveDataByGuid.Remove(InvalidKey);
				PlatformLayoutsDataAsset.MarkPackageDirty();
			}
		}
	}
#endif

	void SetCurrentChallenge(EBombTossChallenges Challenge)
	{
		CurrentChallenge = Challenge;
	}

	EBombTossChallenges GetCurrentChallenge()
	{
		return CurrentChallenge;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//AllPlatformsByGuid = GetPlatformsByGuid();
		AllArmsByGuid = GetArmsByGuid();
	}

	UFUNCTION()
	void SnapPlatformsToPosition(FString LayoutName)
	{
		for (auto Entry : PlatformLayoutsDataAsset.Layouts[LayoutName].ArmMoveDataByGuid)
		{
			if (!AllArmsByGuid.Contains(Entry.Key))
				continue;

			AllArmsByGuid[Entry.Key].SnapToPosition(Entry.Value);
		}
	}

	UFUNCTION(DevFunction)
	void StartMovingPlatforms(FString LayoutName)
	{
		for (auto Entry : PlatformLayoutsDataAsset.Layouts[LayoutName].ArmMoveDataByGuid)
		{
			if (!AllArmsByGuid.Contains(Entry.Key))
				continue;

			if (Entry.Value.MoveDuration <= SMALL_NUMBER)
				AllArmsByGuid[Entry.Key].SnapToPosition(Entry.Value);
			else
				AllArmsByGuid[Entry.Key].StartMoving(Entry.Value);
		}
	}

	FBombTossPlatformPositionValues GetCorrespondingValuesToPosition(EBombTossPlatformPosition Position)
	{
		if (int(Position) >= PlatformPositionValuesDataAsset.PositionValues.Num())
			return FBombTossPlatformPositionValues();

		FBombTossPlatformPositionValues Pos = PlatformPositionValuesDataAsset.PositionValues[Position];
		return Pos;
	}

	TArray<ABombToss_Platform> GetPlatformsSortedY()
	{
		TArray<ABombToss_Platform> PlatformsUnsorted = GetPlatformsSortedX();
		TArray<ABombToss_Platform> PlatformsSorted;

		while (PlatformsUnsorted.Num() > 0)
		{
			float LowestValue = BIG_NUMBER;
			int CurrentIndex = 0;
			float MaxX = PlatformsUnsorted[0].ActorLocation.X;

			for (int i = 0; i < PlatformsUnsorted.Num(); i++)
			{
				if (PlatformsUnsorted[i].ActorLocation.X != MaxX)
					continue;

				if (PlatformsUnsorted[i].ActorLocation.Y < LowestValue)
				{
					LowestValue = PlatformsUnsorted[i].ActorLocation.Y;
					CurrentIndex = i;
				}
			}

			PlatformsSorted.Add(PlatformsUnsorted[CurrentIndex]);
			PlatformsUnsorted.RemoveAt(CurrentIndex);
		}

		return PlatformsSorted;
	}

	TMap<FGuid, ABombToss_Platform> GetPlatformsByGuid()
	{
		TMap<FGuid, ABombToss_Platform> PlatformsByGuid;

		for (auto Platform : TListedActors<ABombToss_Platform>().Array)
			PlatformsByGuid.Add(Platform.PlatformGuid, Platform);

		return PlatformsByGuid;
	}

	TMap<FGuid, AGameShowArenaPlatformArm> GetArmsByGuid()
	{
		TMap<FGuid, AGameShowArenaPlatformArm> ArmsByGuid;

		for (auto Arm : TListedActors<AGameShowArenaPlatformArm>().Array)
			ArmsByGuid.Add(Arm.ArmGuid, Arm);

		return ArmsByGuid;
	}

	TArray<ABombToss_Platform> GetPlatformsSortedX()
	{
		TArray<ABombToss_Platform> PlatformsUnsorted;
		TArray<ABombToss_Platform> PlatformsSorted;

		TListedActors<ABombToss_Platform> Platforms;
		for (auto Platform : Platforms)
			PlatformsUnsorted.Add(Platform);

		while (PlatformsUnsorted.Num() > 0)
		{
			float HighestValue = -BIG_NUMBER;
			int CurrentIndex = 0;

			for (int i = 0; i < PlatformsUnsorted.Num(); i++)
			{
				if (PlatformsUnsorted[i].ActorLocation.X > HighestValue)
				{
					HighestValue = PlatformsUnsorted[i].ActorLocation.X;
					CurrentIndex = i;
				}
			}

			PlatformsSorted.Add(PlatformsUnsorted[CurrentIndex]);
			PlatformsUnsorted.RemoveAt(CurrentIndex);
		}

		return PlatformsSorted;
	}

	UFUNCTION()
	TArray<FString> GetStoredPlatformLayoutNames() const
	{
		TArray<FString> StoredPlatformLayoutNames;
		for (auto LayoutEntry : PlatformLayoutsDataAsset.Layouts)
		{
			StoredPlatformLayoutNames.AddUnique(LayoutEntry.Key);
		}
		return StoredPlatformLayoutNames;
	}

	UFUNCTION()
	TArray<FName> GetStoredPlatformLayoutNamesAsFNames() const
	{
		TArray<FName> StoredPlatformLayoutNames;
		for (auto LayoutEntry : PlatformLayoutsDataAsset.Layouts)
		{
			StoredPlatformLayoutNames.AddUnique(FName(LayoutEntry.Key));
		}
		StoredPlatformLayoutNames.Sort();
		return StoredPlatformLayoutNames;
	}
}