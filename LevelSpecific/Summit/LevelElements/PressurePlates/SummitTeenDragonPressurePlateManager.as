event void FOnSummitBothPressurePlatePressed();

class ASummitTeenDragonPressurePlateManager : AHazeActor
{
	UPROPERTY()
	FOnSummitBothPressurePlatePressed OnSummitBothPressurePlatePressed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY(EditInstanceOnly)
	ASummitTeenDragonPressurePlate PressurePlateLeft;

	UPROPERTY(EditInstanceOnly)
	ASummitTeenDragonPressurePlate PressurePlateRight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PressurePlateLeft.OnSummitTeenDragonPressurePlatePressed.AddUFunction(this, n"OnSummitTeenDragonPressurePlatePressed");
		PressurePlateRight.OnSummitTeenDragonPressurePlatePressed.AddUFunction(this, n"OnSummitTeenDragonPressurePlatePressed");
	}

	UFUNCTION()
	private void OnSummitTeenDragonPressurePlatePressed()
	{
		if (PressurePlateLeft.IsPressurePlatePressed() && PressurePlateRight.IsPressurePlatePressed())
		{
			OnSummitBothPressurePlatePressed.Broadcast();
		}
	}
};