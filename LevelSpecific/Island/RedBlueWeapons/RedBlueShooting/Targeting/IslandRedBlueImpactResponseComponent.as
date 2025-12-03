

event void FIslandRedBlueImpactResponseSignature(FIslandRedBlueImpactResponseParams Data);

struct FIslandRedBlueImpactResponseParams
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly)
	UIslandRedBlueImpactResponseComponent Component;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocation;
	
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactNormal;

	UPROPERTY(BlueprintReadOnly)
	float ImpactDamageMultiplier;

	UPROPERTY(BlueprintReadOnly)
	FVector BulletShootDirection;
}

struct FIslandRedBlueImpactBlocker
{
	TArray<FInstigator> Blockers;

	bool IsActive() const
	{
		return Blockers.Num() > 0;
	}
}

/**
 * A component that responds to impacts made by the red/blue weapons
 * can use 
 */
class UIslandRedBlueImpactResponseComponent : USceneComponent
{
	access BulletAccess = private, UIslandRedBlueShootBulletCapabilityBase (inherited), AIslandRedBlueWeaponBullet (inherited), UIslandRedBlueWeaponUserComponent;
	access BulletAndInheritedAccess = protected, UIslandRedBlueShootBulletCapabilityBase (inherited), AIslandRedBlueWeaponBullet (inherited), UIslandRedBlueWeaponUserComponent;

	// If true, this will only trigger impacts when the parent component is hit
	UPROPERTY(Category = "Red Blue Settings")
	bool bIsPrimitiveParentExclusive = false;

	UPROPERTY(Category = "Events")
	FIslandRedBlueImpactResponseSignature OnImpactEvent;

	private TPerPlayer<FIslandRedBlueImpactBlocker> ImpactBlockers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bIsPrimitiveParentExclusive)
		{
			auto PrimParent = Cast<UPrimitiveComponent>(GetAttachParent());
			devCheck(PrimParent != nullptr, f"{this} on {Owner} is set to 'bIsPrimitiveParentExclusive' but its parent component is not a primitive");
		}
	}

	access:BulletAccess
	void ApplyImpact(FVector BulletShootDirection, AHazePlayerCharacter ImpactInstigator, FHitResult HitResult, float DamageMultiplier)
	{
		OnImpact(ImpactInstigator, HitResult, DamageMultiplier);

		FIslandRedBlueImpactResponseParams EventImpactData;
		EventImpactData.Player = ImpactInstigator;
		EventImpactData.Component = this;
		EventImpactData.ImpactLocation = HitResult.ImpactPoint;
		EventImpactData.ImpactDamageMultiplier = DamageMultiplier;
		EventImpactData.ImpactNormal = HitResult.ImpactNormal;
		EventImpactData.BulletShootDirection = BulletShootDirection;
		OnImpactEvent.Broadcast(EventImpactData);
	}

	access:BulletAndInheritedAccess
	bool CanApplyImpact(const AHazePlayerCharacter ImpactInstigator, FHitResult HitResult) const
	{
		if(!ImpactInstigator.HasControl())
			return false;

		if(ImpactBlockers[ImpactInstigator].IsActive())
			return false;

		// Validate exclusive primitive impact
		if(bIsPrimitiveParentExclusive)
		{
			auto PrimParent = Cast<UPrimitiveComponent>(GetAttachParent());
			if(PrimParent != nullptr && PrimParent != HitResult.Component)
				return false;
		}

		return true;
	}

	protected void OnImpact(AHazePlayerCharacter ImpactInstigator, FHitResult HitResult, float DamageMultiplier)
	{
		BP_OnImpact(ImpactInstigator, HitResult, DamageMultiplier);
	}

	UFUNCTION(BlueprintEvent, Meta = (DisplayName = "OnImpact"))
	protected void BP_OnImpact(AHazePlayerCharacter Player, FHitResult HitResult, float DamageMultiplier)
	{
		
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	void BlockImpact(FInstigator Instigator)
	{
		BlockImpactForPlayer(Game::Mio, Instigator);
		BlockImpactForPlayer(Game::Zoe, Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	void BlockImpactForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		ImpactBlockers[Player].Blockers.AddUnique(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	void BlockImpactForColor(EIslandRedBlueWeaponType Color, FInstigator Instigator)
	{
		ImpactBlockers[IslandRedBlueWeapon::GetPlayerForColor(Color)].Blockers.AddUnique(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	void UnblockImpact(FInstigator Instigator)
	{
		UnblockImpactForPlayer(Game::Mio, Instigator);
		UnblockImpactForPlayer(Game::Zoe, Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	void UnblockImpactForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		ImpactBlockers[Player].Blockers.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	void UnblockImpactForColor(EIslandRedBlueWeaponType Color, FInstigator Instigator)
	{
		ImpactBlockers[IslandRedBlueWeapon::GetPlayerForColor(Color)].Blockers.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	bool IsImpactBlockedForPlayer(AHazePlayerCharacter Player) const
	{
		return ImpactBlockers[Player].IsActive();
	}

	UFUNCTION(BlueprintCallable, Category = "Red Blue Impact")
	bool IsImpactBlockedForColor(EIslandRedBlueWeaponType Color) const
	{
		return ImpactBlockers[IslandRedBlueWeapon::GetPlayerForColor(Color)].IsActive();
	}
};