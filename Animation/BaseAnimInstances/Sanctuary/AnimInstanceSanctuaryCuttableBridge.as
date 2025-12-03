class UAnimInstanceSanctuaryCuttableBridge : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Cut;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Fall;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCutLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCutRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFall;

	ASanctuaryCutableDrawBridge Bridge;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor != nullptr)
			Bridge = Cast<ASanctuaryCutableDrawBridge>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Bridge == nullptr)
			return;

		bCutLeft = Bridge.bCutRight;
		bCutRight = Bridge.bCutLeft;
		bFall = Bridge.bFall;
	}
}