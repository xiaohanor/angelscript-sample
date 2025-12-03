
UCLASS(Abstract)
class UGameplay_Vehicle_WingsuitTunnelTrain_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPrimitiveComponent TrainUndersideBox;

	UPROPERTY(EditDefaultsOnly, Category = "Emitters")
	UHazeAudioEmitter UndersidePlaneEmitter;

	TArray<FAkSoundPosition> Positions;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Positions.SetNum(2);
		TrainUndersideBox = UPrimitiveComponent::Get(HazeOwner, n"TrainUndersideBox");

		Positions[0] = FAkSoundPosition(FVector());
		Positions[1] = FAkSoundPosition(FVector());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		SetUndersideMultiPos();
	}

	private void SetUndersideMultiPos()
	{
		if(TrainUndersideBox == nullptr)
			return;

		AHazePlayerCharacter Mio;
		AHazePlayerCharacter Zoe;

		Game::GetMioZoe(Mio, Zoe);

		FVector BoxPosMio;
		FVector BoxPosZoe;

		TrainUndersideBox.GetClosestPointOnCollision(Mio.GetActorLocation(), BoxPosMio);
		TrainUndersideBox.GetClosestPointOnCollision(Zoe.GetActorLocation(), BoxPosZoe);

		Positions[0].SetPosition(BoxPosMio);
		Positions[1].SetPosition(BoxPosZoe);

		UndersidePlaneEmitter.GetAudioComponent().SetMultipleSoundPositions(Positions);
	}
}