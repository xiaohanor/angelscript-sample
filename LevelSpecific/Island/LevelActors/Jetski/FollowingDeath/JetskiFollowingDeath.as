enum EJetskiFollowingDeathExplosionMode
{
	Always,
	OnlyWhenPlayerClose,
	OnPlayerKilled
}

namespace AJetskiFollowingDeath
{
	AJetskiFollowingDeath Get()
	{
		return TListedActors<AJetskiFollowingDeath>().Single;
	}
};

UCLASS(Abstract)
class AJetskiFollowingDeath : AHazeActor
{
	access Active = private, UJetskiFollowingDeathActiveCapability;
	access Move = private, UJetskiFollowingDeathMoveCapability;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"JetskiFollowingDeathActiveCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"JetskiFollowingDeathMoveCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"JetskiFollowingDeathExplosionsCapability");

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UPROPERTY(EditInstanceOnly)
	bool bDebugDraw = false;
#endif

	/**
	 * How far behind the leading player we need to be to use the MinMoveSpeed
	 */
	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	float MinSpeedMargin = 1000;

	/**
	 * How far behind the leading player we need to be to fully use the MaxMoveSpeed
	 */
	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	float MaxSpeedMargin = 10000;

	/**
	 * How fast to move when we have caught up to MinSpeedMargin
	 */
	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	float MinMoveSpeed = 1000;

	/**
	 * How fast to move when we are behind the MaxSpeedMargin
	 */
	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	float MaxMoveSpeed = 4000;

	UPROPERTY(EditDefaultsOnly, Category = "Explosions")
	EJetskiFollowingDeathExplosionMode ExplosionMode = EJetskiFollowingDeathExplosionMode::OnlyWhenPlayerClose;
	
	UPROPERTY(EditDefaultsOnly, Category = "Explosions")
	TArray<UNiagaraSystem> Explosions;

	UPROPERTY(EditDefaultsOnly, Category = "Explosions")
	float ExplosionMinInterval = 0.4;

	UPROPERTY(EditDefaultsOnly, Category = "Explosions")
	float ExplosionMaxInterval = 1.0;

	UPROPERTY(EditDefaultsOnly, Category = "Explosions")
	float ExplosionSplineWidthDivider = 3000;

	UPROPERTY(EditDefaultsOnly, Category = "Explosions|OnlyWhenPlayerClose", Meta = (EditCondition = "ExplosionMode == EJetskiFollowingDeathExplosionMode::OnlyWhenPlayerClose"))
	float PlayerCloseMargin = 2000;

	UPROPERTY(EditDefaultsOnly, Category = "Explosions|OnPlayerKilled", Meta = (EditCondition = "ExplosionMode == EJetskiFollowingDeathExplosionMode::OnPlayerKilled"))
	float OnPlayerKilledExplosionDuration = 1.5;

	access:Active
	bool bIsActive = false;

	access:Move
	float DistanceAlongSpline = -1;

	access:Move
	float LastPlayerKillTime = -1000;

	bool IsActive() const
	{
		return bIsActive;
	}

	float GetDistanceAlongSpline() const
	{
		return DistanceAlongSpline;
	}

	FVector GetWorldLocation() const
	{
		return Jetski::GetJetskiSpline().Spline.GetWorldLocationAtSplineDistance(DistanceAlongSpline);
	}

	float GetLastPlayerKillTime() const
	{
		return LastPlayerKillTime;
	}
};