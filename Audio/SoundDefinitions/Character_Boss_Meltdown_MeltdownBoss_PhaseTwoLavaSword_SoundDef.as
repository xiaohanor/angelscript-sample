
UCLASS(Abstract)
class UCharacter_Boss_Meltdown_MeltdownBoss_PhaseTwoLavaSword_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void StartHorizontalSwing(){}

	UFUNCTION(BlueprintEvent)
	void StopHorizontalSwing(){}

	UFUNCTION(BlueprintEvent)
	void StartVerticalSwing(){}

	UFUNCTION(BlueprintEvent)
	void VerticalSwingHit(FMeltdownBossPhaseTwoFireSwordHitParams HitParams){}

	UFUNCTION(BlueprintEvent)
	void StartHorizontalSwingLeft(){}

	UFUNCTION(BlueprintEvent)
	void StartHorizontalSwingRight(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UHazeAudioEmitter ShockwaveMultiEmitter;
	private TArray<AMeltdownPhaseTwoLavaSwordShockwave> Shockwaves;
	private TArray<FAkSoundPosition> ShockwaveSoundPositions;
	default ShockwaveSoundPositions.SetNum(4);

	AMeltdownBossPhaseTwoFireSword LavaSword;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		LavaSword = Cast<AMeltdownBossPhaseTwoFireSword>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(LavaSword.GetActiveShockwaves(Shockwaves))
		{
			const FVector MioPos = Game::Mio.ActorLocation;
			const FVector ZoePos = Game::Zoe.ActorLocation;

			for(int i = 0; i < 2; ++i)
			{
				auto Shockwave = Shockwaves[i];
				if(Shockwave != nullptr)
				{
					const FVector ShockwaveStart = Shockwave.Trigger.WorldLocation - FVector(1000, 0.0, 0.0);
					const FVector ShockwaveEnd = Shockwave.Trigger.WorldLocation + FVector(1000, 0.0, 0.0);
				
					const FVector ClosestMioPos = Math::ClosestPointOnLine(ShockwaveStart, ShockwaveEnd, MioPos);
					const FVector ClosestZoePos = Math::ClosestPointOnLine(ShockwaveStart, ShockwaveEnd, ZoePos);
					ShockwaveSoundPositions[i].SetPosition(ClosestMioPos);
					ShockwaveSoundPositions[i+2].SetPosition(ClosestZoePos);
				}
			}		

			ShockwaveMultiEmitter.SetMultiplePositions(ShockwaveSoundPositions);
		}
	}
}