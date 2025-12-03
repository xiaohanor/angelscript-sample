struct FStoneBeastFlakeAnimActorData
{
	UPROPERTY(EditInstanceOnly)
	AHazeAnimActor AnimActor;

	UPROPERTY(EditInstanceOnly)
	UAnimSequence ClosedMH;

	UPROPERTY(EditInstanceOnly)
	UAnimSequence OpenMH;
}

class AStoneBeastHeadAnimActorCoverManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visuals;
	default Visuals.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ClosedMH;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence OpenMH;

	UPROPERTY(EditInstanceOnly)
	TArray<FStoneBeastFlakeAnimActorData> AnimActorDatas;

	FHazeSlotAnimSettings Settings;
	default Settings.bLoop = true;

	UFUNCTION()
	void SetClosedAnims()
	{
		for (FStoneBeastFlakeAnimActorData& Data : AnimActorDatas)
		{
			Data.AnimActor.PlaySlotAnimation(Data.ClosedMH, Settings);
		}
	}
	
	UFUNCTION()
	void SetOpenAnims()
	{
		for (FStoneBeastFlakeAnimActorData& Data : AnimActorDatas)
		{
			Data.AnimActor.PlaySlotAnimation(Data.OpenMH, Settings);
		}
	}
};