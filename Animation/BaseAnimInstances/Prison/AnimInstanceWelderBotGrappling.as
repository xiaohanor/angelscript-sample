class UAnimInstanceWelderBotGrappling : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform Transform;

	const FTransform OFFSET = FTransform(FRotator(70, 0, 180), FVector(-12, 0, -4));

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Game::Zoe == nullptr)
			return;

		Transform = OFFSET * Game::Zoe.Mesh.GetSocketTransform(n"Spine2");
	}
}