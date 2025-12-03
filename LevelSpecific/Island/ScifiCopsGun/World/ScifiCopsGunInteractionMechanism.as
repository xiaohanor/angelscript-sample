
class AScifiCopsGunInteractionMechanism : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UScifiCopsGunThrowTargetableComponent Tragetable;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunImpactResponseComponent ImpactResponse;

	UPROPERTY()
	bool bCanShootWhileAttached = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactResponse.OnWeaponImpact.AddUFunction(this, n"OnWeaponImpactInternal");
		ImpactResponse.OnWeaponReturningToPlayer.AddUFunction(this, n"OnWeaponReturnInternal");
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnWeaponImpactInternal(AHazePlayerCharacter ImpactInstigator)
	{
		OnWeaponImpact();
		if(bCanShootWhileAttached)
		{
			
		}
	}

	
	UFUNCTION(NotBlueprintCallable)
	protected void OnWeaponReturnInternal(AHazePlayerCharacter ImpactInstigator)
	{
		
	}

	/** Override to handle the impact */
	UFUNCTION(NotBlueprintCallable, BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeaponImpact()
	{
		
	}
}