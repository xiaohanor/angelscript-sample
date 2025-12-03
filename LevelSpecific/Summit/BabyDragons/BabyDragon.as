
UCLASS(Abstract, NotPlaceable)
class ABabyDragon : AHazeCharacter
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter Player;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent PoseDebugComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	UPROPERTY(EditAnywhere)
	float WingFlappingStrength = 1.0;
};

namespace BabyDragon
{
	const FName BabyDragon = n"BabyDragon";
	
	UFUNCTION(BlueprintCallable, BlueprintPure)
	ABabyDragon GetBabyTailDragon()
	{
		return UPlayerBabyDragonComponent::Get(Game::Zoe).BabyDragon;
	}
	
	UFUNCTION(BlueprintCallable, BlueprintPure)
	ABabyDragon GetBabyAcidDragon()
	{
		return UPlayerBabyDragonComponent::Get(Game::Mio).BabyDragon;
	}

	UFUNCTION(BlueprintCallable)
	void DetachAcidDragon()
	{
		UPlayerBabyDragonComponent::Get(Game::Zoe).DettachBabyDragon(Game::Zoe);
	}
	
	UFUNCTION(BlueprintCallable)
	void DetachTailDragon()
	{
		UPlayerBabyDragonComponent::Get(Game::Mio).DettachBabyDragon(Game::Mio);
	}
}