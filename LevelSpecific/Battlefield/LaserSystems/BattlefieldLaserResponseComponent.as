event void FOnBattlefieldLaserImpact();

class UBattlefieldLaserResponseComponent : UActorComponent
{	
	UPROPERTY()
	FOnBattlefieldLaserImpact OnBattlefieldLaserImpact;

	void ApplyImpact()
	{
		OnBattlefieldLaserImpact.Broadcast();
	}
};