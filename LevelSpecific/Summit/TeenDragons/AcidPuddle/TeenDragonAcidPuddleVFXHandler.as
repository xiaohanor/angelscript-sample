
struct FTeenDragonAcidPuddleEnterVFXData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;
}

struct FTeenDragonAcidPuddleExitVFXData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;
}

struct FTeenDragonAcidPuddleTrailExplodeVFXData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	// True if this is the one on the dragon
	UPROPERTY(BlueprintReadOnly)
	bool bIsHeadOfTrail = false;
}


UCLASS(Abstract)
class UTeenDragonAcidPuddleVFXHandler : UHazeEffectEventHandler
{

	// Responde to 'AcidPuddle.OnPuddleEnter'
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPuddleEnter(FTeenDragonAcidPuddleEnterVFXData Data) 
	{

	}

	// Responde to 'AcidPuddle.OnPuddleExit'
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPuddleExit(FTeenDragonAcidPuddleExitVFXData Data) 
	{

	}

	// Responde to 'AcidPuddle.OnTrailExplode'
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTrailExplode(FTeenDragonAcidPuddleTrailExplodeVFXData Data) 
	{

	}

}