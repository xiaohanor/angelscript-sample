event void FOnMeltdownGlitchHit(FMeltdownGlitchImpact Impact);

struct FMeltdownGlitchImpact
{
	UPROPERTY()
	AHazePlayerCharacter FiringPlayer;
	UPROPERTY()
	FVector ImpactPoint;
	UPROPERTY()
	FVector ImpactNormal;
	UPROPERTY()
	FVector ProjectileDirection;
	UPROPERTY()
	float Damage = 1.0;
}

class UMeltdownGlitchShootingResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnMeltdownGlitchHit OnGlitchHit;

	bool bShouldLeadTargetByActorVelocity = false;

	void TriggerGlitchHit(FMeltdownGlitchImpact Impact)
	{
		if (Impact.FiringPlayer.HasControl())
			CrumbGlitchHit(Impact);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbGlitchHit(FMeltdownGlitchImpact Impact)
	{
		OnGlitchHit.Broadcast(Impact);
	}
};