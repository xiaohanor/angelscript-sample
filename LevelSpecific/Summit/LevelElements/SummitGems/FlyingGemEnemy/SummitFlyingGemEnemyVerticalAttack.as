event void FSummitFlyingGemEnemyVerticalAttackSignature();

class ASummitFlyingGemEnemyVerticalAttack : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttackOrigin;

    UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DeathVolumePosition;

    UPROPERTY(EditAnywhere)
    ASummitQuarryLift QuarryLift;

    UPROPERTY(EditAnywhere)
    ADeathVolume DeathVolume;

    bool bIsActive;

    UPROPERTY(EditAnywhere)
    float AttackInterval = 3;
    float AttackIntervalTimer;
    float TimeLikeTimer = 2;

    UPROPERTY(Category = "Niagara Systems")
	UNiagaraSystem AttackEffect;

    UPROPERTY(Category = "Niagara Systems")
	UNiagaraSystem MuzzleEffect;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        // AttackIntervalTimer = AttackInterval + TimeLikeTimer;
        if (DeathVolume != nullptr)
            DeathVolume.AttachToComponent(DeathVolumePosition);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
        if (!bIsActive)
            return;

        AttackIntervalTimer = AttackIntervalTimer - DeltaTime;

        if (AttackIntervalTimer <= 0)
        {
            Attack();
            AttackIntervalTimer = AttackInterval + TimeLikeTimer;
        }

	}

    UFUNCTION()
    void Activate()
    {
        bIsActive = true;
    }

    UFUNCTION()
    void Deactivate()
    {
        bIsActive = false;
    }

    void Attack()
    {
        BP_Attack();
    }

    UFUNCTION(BlueprintEvent)
    void BP_Attack()
    {

    }

}