
UCLASS(Abstract)
class UWorld_Tundra_MonkeyRealm_Interactable_TotemPuzzle_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void PuzzleSolved(){}

	UFUNCTION(BlueprintEvent)
	void TriedToGroundSlamWhileTotemAtBottom(FTotemPuzzleEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void TriedToMoveTotemUpButIsAsHighAsItGoes(FTotemPuzzleEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void TriedToMoveTotemDownButIsAsLowAsItGoes(FTotemPuzzleEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void TotemGroundSlammed(FTotemPuzzleEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void TotemMovingDown(FTotemPuzzleEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void TotemMovingUp(FTotemPuzzleEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void TotemStartShaking(FTotemPuzzleEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void TotemReachedBottom(FTotemPuzzleEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void TriedWrongSolution(){}

	/* END OF AUTO-GENERATED CODE */

	const int NUM_TOTEMS = 3;

	private TArray<UHazeAudioEmitter> TotemEmitters;
	default TotemEmitters.SetNum(NUM_TOTEMS);

	UPROPERTY(BlueprintReadOnly, Category = "Totem Emitters")
	UHazeAudioEmitter LeftTotemEmitter;

	UPROPERTY(BlueprintReadOnly, Category = "Totem Emitters")
	UHazeAudioEmitter MiddleTotemEmitter;

	UPROPERTY(BlueprintReadOnly, Category = "Totem Emitters")
	UHazeAudioEmitter RightTotemEmitter;

	UPROPERTY(BlueprintReadOnly, Category = "Totem Emitters")
	UHazeAudioEmitter TotemsFireMultiEmitter;

	private TArray<FVector> TotemsFireStandLocations;

	ATundra_River_TotemPuzzle_TreeControl PuzzleTreeControl;

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{

		auto TreeControl = Cast<ATundra_River_TotemPuzzle_TreeControl>(HazeOwner);	
		ComponentName = n"TotemRoot";

		if(EmitterName == n"LeftTotemEmitter")
		{
			bUseAttach = true;
			TargetActor = TreeControl.ListOfTotems[ETundraTotemIndex::Left];
		}
		else if(EmitterName == n"MiddleTotemEmitter")
		{
			bUseAttach = true;
			TargetActor = TreeControl.ListOfTotems[ETundraTotemIndex::Middle];
		}
		else if(EmitterName == n"RightTotemEmitter")
		{
			bUseAttach = true;
			TargetActor = TreeControl.ListOfTotems[ETundraTotemIndex::Right];
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		TotemEmitters[0] = LeftTotemEmitter;
		TotemEmitters[1] = MiddleTotemEmitter;
		TotemEmitters[2] = RightTotemEmitter;

		PuzzleTreeControl = Cast<ATundra_River_TotemPuzzle_TreeControl>(HazeOwner);	
		GetTotemFireStandLocations(TotemsFireStandLocations);

		TArray<FAkSoundPosition> FireEmitterSoundPositions;		
		for(auto& Pos : TotemsFireStandLocations)
		{
			FireEmitterSoundPositions.Add(FAkSoundPosition(Pos));
		}

		TotemsFireMultiEmitter.GetAudioComponent().SetMultipleSoundPositions(FireEmitterSoundPositions, AkMultiPositionType::MultiSources);
	}

	UFUNCTION(BlueprintPure)
	void GetTotemEmitter(const ETundraTotemIndex Totem, UHazeAudioEmitter&out OutEmitter)
	{
		if(!devEnsure(int(Totem) >= 0  && int(Totem) < NUM_TOTEMS, f"Invalid Totem-index supplied when retreving emitter in {GetName()}"))
			return;
		
		OutEmitter = TotemEmitters[Totem];
	}

	UFUNCTION(BlueprintPure)
	void GetTotemEmitters(TArray<UHazeAudioEmitter>&out OutEmitters)
	{
		OutEmitters = TotemEmitters;
	}

	private void GetTotemFireStandLocations(TArray<FVector>& OutLocations)
	{
		for(auto& Totem : PuzzleTreeControl.ListOfTotems)
		{
			auto FireStandNiagareEmitter = USceneComponent::Get(Totem, n"EnvironmentFireStand_01");
			OutLocations.Add(FireStandNiagareEmitter.GetWorldLocation());
		}
	}
	
}