event void FonSwordComplete();

class AMeltdownBossPhaseTwoFireSword : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent SwordRoot;

	UPROPERTY(DefaultComponent, Attach = SwordRoot)
	UHazeMovablePlayerTriggerComponent SwordHitBox;

	UPROPERTY(DefaultComponent)
	USceneComponent TelegraphRoot;

	UPROPERTY(DefaultComponent, Attach = SwordRoot)
	USceneComponent SwordSweepShakeLocation;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> SwordSweepShake;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> SlamShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect SlamForceFeedback;

	UPROPERTY(DefaultComponent, Attach = SwordRoot)
	UForceFeedbackComponent SweepFF;

	FVector HitImpulse;
	bool bOnlyHitGroundedPlayers = false;
	AMeltdownBossPhaseTwo Rader;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDamageEffect> SwordDamage;

	// Cached here for audio polling, can be nullptr obviously
	access PrivateWithMeltdownLavaSwordAttackCapability = private, UMeltdownPhaseTwoLavaSwordAttackCapability;
	access:PrivateWithMeltdownLavaSwordAttackCapability TArray<AMeltdownPhaseTwoLavaSwordShockwave> CurrentShockwaves;
	default CurrentShockwaves.SetNum(2);
	bool GetActiveShockwaves(TArray<AMeltdownPhaseTwoLavaSwordShockwave>&out Shockwaves)
	{
		Shockwaves = CurrentShockwaves;
		return !Shockwaves.IsEmpty();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		SweepFF.Play();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (SwordHitBox.IsPlayerInTrigger(Player) && !Player.IsPlayerInvulnerable())
			{
				if (!bOnlyHitGroundedPlayers || Player.IsOnWalkableGround())
				{
					Player.AddKnockbackImpulse(HitImpulse.GetSafeNormal2D(), HitImpulse.Size(), 1200);
					Player.DamagePlayerHealth(0.5, DamageEffect = SwordDamage);

					FMeltdownBossPhaseTwoSwordHitPlayerParams HitPlayerParams;
					HitPlayerParams.Player = Player;
					UMeltdownBossPhaseTwoFireSwordEffectHandler::Trigger_SwordHitPlayer(Rader, HitPlayerParams);
				}
			}
		}
			
	}

	UFUNCTION()
	void PlayCameraShakeSweep()
	{
	//	for (AHazePlayerCharacter Player : )
	}

	UFUNCTION()
	void PlayCameraShakeSlam()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
//			Player.PlayWorldCameraShake(SlamShake, this, )
		}
	}
};


struct FMeltdownBossPhaseTwoFireSwordHitParams
{
	UPROPERTY()
	FVector HitLocation;
}

struct FMeltdownBossPhaseTwoSwordHitPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UMeltdownBossPhaseTwoFireSwordEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartHorizontalSwing() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartHorizontalSwingLeft() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartHorizontalSwingRight() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopHorizontalSwing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartVerticalSwing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void VerticalSwingHit(FMeltdownBossPhaseTwoFireSwordHitParams HitParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SwordHitPlayer(FMeltdownBossPhaseTwoSwordHitPlayerParams HitParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ShockwaveHitPlayer(FMeltdownBossPhaseTwoSwordHitPlayerParams HitParams) {}
}