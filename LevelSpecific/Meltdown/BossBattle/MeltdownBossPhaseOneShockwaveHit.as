class AMeltdownBossPhaseOneShockwaveHit : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	AMeltdownBossPhaseOneShockwaveMissile Missile;

	float Speed = 200;

	UPROPERTY(EditAnywhere)
	float ShockwaveStart;

	UPROPERTY(EditAnywhere)
	float ShockwaveEnd;

	UPROPERTY(DefaultComponent )
	UMeltdownBossCubeGridDisplacementComponent ShockwaveDisplace;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ImpactAnim;
	default ImpactAnim.Duration = 1;
	default ImpactAnim.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FHazeTimeLike FallAnim;
	default FallAnim.Duration = 1;
	default FallAnim.UseLinearCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ShockwaveAnim;
	default ShockwaveAnim.Duration = 1;
	default ShockwaveAnim.UseLinearCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

};