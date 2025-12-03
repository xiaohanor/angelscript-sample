event void FBasicAIKnockdownEvent(FBasicAIKnockdownData Data);

enum EBasicAIKnockdownType
{
	None,
	Default
}

struct FBasicAIKnockdownData
{
	FVector Force;
	EBasicAIKnockdownType BasicAIKnockdownType = EBasicAIKnockdownType::None;
}

class UBasicAIKnockdownComponent : UActorComponent
{	
	UPROPERTY()
	FBasicAIKnockdownData LastKnockdown;

	UPROPERTY()
	FBasicAIKnockdownEvent OnKnockdown;

	UPROPERTY()
	FBasicAIKnockdownEvent OnConsumed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UHazeActorRespawnableComponent Respawn = UHazeActorRespawnableComponent::Get(Owner);
		if(Respawn != nullptr)
			Respawn.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION()
	private void OnReset()
	{
		ConsumeKnockdown();
	}

	UFUNCTION()
	void Knockdown(EBasicAIKnockdownType BasicAIKnockdownType, FVector Force)
	{
		LastKnockdown.BasicAIKnockdownType = BasicAIKnockdownType;
		LastKnockdown.Force = Force;

		if (BasicAIKnockdownType != EBasicAIKnockdownType::None)
			OnKnockdown.Broadcast(LastKnockdown);
	}

	void ConsumeKnockdown()
	{
		OnConsumed.Broadcast(LastKnockdown);
		LastKnockdown = FBasicAIKnockdownData();		
	}

	bool HasKnockdown()
	{
		if (LastKnockdown.BasicAIKnockdownType == EBasicAIKnockdownType::None)
			return false;
		
		return true;
	}
}