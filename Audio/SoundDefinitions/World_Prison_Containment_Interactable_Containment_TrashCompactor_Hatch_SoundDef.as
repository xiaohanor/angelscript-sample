
UCLASS(Abstract)
class UWorld_Prison_Containment_Interactable_Containment_TrashCompactor_Hatch_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void StartFinalCrush(){}

	UFUNCTION(BlueprintEvent)
	void StopCrushing(){}

	UFUNCTION(BlueprintEvent)
	void PushedByMagnet(){}

	UFUNCTION(BlueprintEvent)
	void CloseHatch(FTrashCompactorHatchParams Hatch){}

	UFUNCTION(BlueprintEvent)
	void OpenHatch(FTrashCompactorHatchParams Hatch){}

	UFUNCTION(BlueprintEvent)
	void StartCrushing(){}

	UFUNCTION(BlueprintEvent)
	void RevealCrusher(){}

	/* END OF AUTO-GENERATED CODE */

	const int NUM_HATCHES = 4;

	private TArray<UHazeAudioEmitter> HatchEmitters;
	default HatchEmitters.SetNum(NUM_HATCHES);

	UPROPERTY(Category = "Hatch Emitters")
	UHazeAudioEmitter LeftFrontHatchEmitter;

	UPROPERTY(BlueprintReadOnly, Category = "Hatch Emitters")
	UHazeAudioEmitter LeftBackHatchEmitter;

	UPROPERTY(BlueprintReadOnly, Category = "Hatch Emitters")
	UHazeAudioEmitter RightFrontHatchEmitter;

	UPROPERTY(BlueprintReadOnly, Category = "Hatch Emitters")
	UHazeAudioEmitter RightBackHatchEmitter;

	UPROPERTY()
	ATrashCompactor TrashCompactor;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		HatchEmitters[0] = LeftFrontHatchEmitter;
		HatchEmitters[1] = RightBackHatchEmitter;
		HatchEmitters[2] = RightFrontHatchEmitter;
		HatchEmitters[3] = LeftBackHatchEmitter;

		TrashCompactor = Cast<ATrashCompactor>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	bool IsCrushing() const
	{
		return TrashCompactor != nullptr && TrashCompactor.bCrushing;
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;

		if(EmitterName == n"LeftFrontHatchEmitter")
		{
			ComponentName = n"LeftFrontMagneticPad";
			bUseAttach = true;
		}
		else if(EmitterName == n"RightBackHatchEmitter")
		{
			ComponentName = n"RightBackMagneticPad";
			bUseAttach = true;
		}
		else if(EmitterName == n"RightFrontHatchEmitter")
		{
			ComponentName = n"RightFrontMagneticPad";
			bUseAttach = true;
		}
		else if(EmitterName == n"LeftBackHatchEmitter")
		{
			ComponentName = n"LeftBackMagneticPad";
			bUseAttach = true;
		}

		return true;		
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEmitter GetHatchEmitter(const int HatchIndex)
	{
		if(!devEnsure(HatchIndex >= 0, "Invalid hatch index when retreiving SoundDef emitter!"))
			return nullptr;

		return HatchEmitters[HatchIndex];
	}

	UFUNCTION(BlueprintPure)
	void GetHatchEmitters(TArray<UHazeAudioEmitter>&out OutHatchEmitters)
	{
		OutHatchEmitters = Emitters;
	}
}