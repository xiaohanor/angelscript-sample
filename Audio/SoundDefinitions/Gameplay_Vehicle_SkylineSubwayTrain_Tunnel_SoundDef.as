
UCLASS(Abstract)
class UGameplay_Vehicle_SkylineSubwayTrain_Tunnel_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPrimitiveComponent TrainUndersideBox;

	UPROPERTY(EditDefaultsOnly, Category = "Emitters")
	UHazeAudioEmitter UndersidePlaneEmitter;

	UPROPERTY(EditInstanceOnly, Category = "Emitters")
	UHazeAudioEmitter EmitterContainer1;

	UPROPERTY(EditInstanceOnly, Category = "Emitters")
	UHazeAudioEmitter EmitterContainer2;

	UPROPERTY(EditInstanceOnly, Category = "Emitters")
	UHazeAudioEmitter EmitterContainer3;

	UPROPERTY(EditInstanceOnly, Category = "Emitters")
	UHazeAudioEmitter EmitterContainer4;

	UPROPERTY(EditInstanceOnly, Category = "Emitters")
	UHazeAudioEmitter EmitterContainer5;

	UPROPERTY(EditInstanceOnly, Category = "Emitters")
	UHazeAudioEmitter EmitterContainer6;

	UPROPERTY(EditInstanceOnly, Category = "Emitters")
	UHazeAudioEmitter EmitterRear;

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
	void OnActivated()
	{
		GetZoneOcclusionValue(DefaultEmitter,true,nullptr,true);
		GetZoneOcclusionValue(EmitterContainer1,true,nullptr,true);
		GetZoneOcclusionValue(EmitterContainer2,true,nullptr,true);
		GetZoneOcclusionValue(EmitterContainer3,true,nullptr,true);
		GetZoneOcclusionValue(EmitterContainer4,true,nullptr,true);
		GetZoneOcclusionValue(EmitterContainer5,true,nullptr,true);
		GetZoneOcclusionValue(EmitterContainer6,true,nullptr,true);
		GetZoneOcclusionValue(EmitterRear,true,nullptr,true);
		GetZoneOcclusionValue(UndersidePlaneEmitter,true,nullptr,true);
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