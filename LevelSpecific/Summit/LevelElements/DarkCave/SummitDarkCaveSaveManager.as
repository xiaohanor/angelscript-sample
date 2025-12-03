enum EDarkCaveSaveStatueState
{
	Statue1,
	Statue2,
	Statue3,
	Statue4
}

struct FSummitDarkCaveSaveData
{
	UPROPERTY(EditAnywhere)
	FName Statue;
	UPROPERTY(EditAnywhere)
	TArray<AActor> PersistentActors;
}

event void FOnStatueThreeSaveActivated();

class ASummitDarkCaveSaveManager : AHazeActor
{
	UPROPERTY()
	FOnStatueThreeSaveActivated OnStatueThreeSaveActivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(EditAnywhere)
	TArray<FSummitDarkCaveSaveData> SaveData;

	UFUNCTION()
	void SetSaveState(int Index)
	{
		Save::ModifyPersistentProfileFlag(EHazeSaveDataType::Progress, SaveData[Index].Statue, true);
	}

	UFUNCTION()
	void ActivateSaveState()
	{
		for (FSummitDarkCaveSaveData Data : SaveData)
		{
			if (Save::IsPersistentProfileFlagSet(EHazeSaveDataType::Progress, Data.Statue))
			{
				for (AActor Actor : Data.PersistentActors)
					USummitDarkCaveSaveComponent::Get(Actor).ActivateSaveState();

				if (Data.Statue == n"Statue3")
					OnStatueThreeSaveActivated.Broadcast();
			}
		}
	}

	UFUNCTION()
	void ClearSaveState()
	{
		for (FSummitDarkCaveSaveData Data : SaveData)
		{
			Save::ModifyPersistentProfileFlag(EHazeSaveDataType::Progress, Data.Statue, false);
		}
	}
};