
struct FCopsGunBulletImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;
}

event void FScifiCopsGunShootImpactResponseSignature(AHazePlayerCharacter ImpactInstigator, FCopsGunBulletImpactParams ImpactParams);
event void FScifiCopsGunThrowImpactResponseSignature(AHazePlayerCharacter ImpactInstigator);

class UScifiCopsGunImpactResponseComponent : UActorComponent
{
	// Called when a bullet hits the actor with this component
	UPROPERTY(Category = "Impact")
	FScifiCopsGunShootImpactResponseSignature OnBulletImpact;

	// Called when the weapon is attached to the owner of this component
	UPROPERTY(Category = "Impact")
	FScifiCopsGunThrowImpactResponseSignature OnWeaponImpact;

	// Called when the weapon is "done" with the current point and is returning to the player
	UPROPERTY(Category = "Impact")
	FScifiCopsGunThrowImpactResponseSignature OnWeaponReturningToPlayer;


	void ApplyBulletImpact(AHazePlayerCharacter FromPlayer, FCopsGunBulletImpactParams ImpactParams)
	{
		OnApplyBulletImpact(FromPlayer, ImpactParams);
		OnBulletImpact.Broadcast(FromPlayer, ImpactParams);
	}

	void ApplyWeaponImpact(AHazePlayerCharacter FromPlayer)
	{
		OnApplyWeaponImpact(FromPlayer);
		OnWeaponImpact.Broadcast(FromPlayer);
	}

	void ApplyWeaponReturningToPlayer(AHazePlayerCharacter FromPlayer)
	{
		OnApplyWeaponReturningToPlayer(FromPlayer);
		OnWeaponReturningToPlayer.Broadcast(FromPlayer);
	}

	UFUNCTION(BlueprintEvent)
	protected void OnApplyBulletImpact(AHazePlayerCharacter FromPlayer, FCopsGunBulletImpactParams ImpactParams)
	{
		
	}

	UFUNCTION(BlueprintEvent)
	protected void OnApplyWeaponImpact(AHazePlayerCharacter FromPlayer)
	{
		
	}

	UFUNCTION(BlueprintEvent)
	protected void OnApplyWeaponReturningToPlayer(AHazePlayerCharacter FromPlayer)
	{
		
	}
}


