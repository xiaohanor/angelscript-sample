
UCLASS(Abstract)
class UCharacter_Boss_Prison_DarkMio_Attack_Scissors_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void ScissorsFinished(){}

	UFUNCTION(BlueprintEvent)
	void ScissorsExit(){}

	UFUNCTION(BlueprintEvent)
	void ScissorsAttackSpawned(){}

	UFUNCTION(BlueprintEvent)
	void ScissorsEnter(){}

	/* END OF AUTO-GENERATED CODE */

	APrisonBoss DarkMio;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter ScissorMultiEmitter;

	private TArray<FAkSoundPosition> ScissorSoundPositions;
	default ScissorSoundPositions.SetNum(2);

	//Need: CurrentSweepDuration	

	UPROPERTY(BlueprintReadOnly)
	float SweepAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DarkMio = Cast<APrisonBoss>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = DarkMio;
		
		if(EmitterName == n"ScissorMultiEmitter")
			bUseAttach = false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DarkMio.CurrentAttackType == EPrisonBossAttackType::Scissors;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return DarkMio.CurrentAttackType != EPrisonBossAttackType::Scissors;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{		
		TArray<APrisonBossScissorsAttack> Sciccors = TListedActors<APrisonBossScissorsAttack>().GetArray();
		if(!Sciccors.IsEmpty())
		{
			for(int i = 0; i < 2; ++i)
			{		
				APrisonBossScissorsAttack Scissor = Sciccors[i];				
				const FVector LineStart = Scissor.ScissorsRoot.WorldLocation;
				const FVector LineEnd = LineStart + (Scissor.ScissorsRoot.ForwardVector * 4000.0);
				const FVector ClosestZoeLocation = Math::ClosestPointOnLine(LineStart, LineEnd, Game::GetZoe().ActorLocation);
				ScissorSoundPositions[i].SetPosition(ClosestZoeLocation);		
			}

			ScissorMultiEmitter.SetMultiplePositions(ScissorSoundPositions);

			// FRotator Rot = Sciccors[0].RotationRoot.RelativeRotation;	
			// SweepAlpha = Math::GetMappedRangeValueClamped(FVector2D(-45, 45.0), FVector2D(-1.0, 1.0), Rot.Yaw);

			SweepAlpha = Sciccors[0].SweepAlpha;
		}
		
	}
}