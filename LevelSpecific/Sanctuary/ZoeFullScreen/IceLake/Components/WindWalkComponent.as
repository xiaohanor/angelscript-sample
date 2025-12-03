struct FWindWalkAnimationData
{
    UPROPERTY(BlueprintReadOnly)
	float ForwardFactor;

    UPROPERTY(BlueprintReadOnly)
	float RightFactor;

	UPROPERTY(BlueprintReadOnly)
	float PlayRate;

	UPROPERTY(BlueprintReadOnly)
    FVector HorizontalVelocity;

    UPROPERTY(BlueprintReadOnly)
    FVector MovementInput;

    UPROPERTY(BlueprintReadOnly)
    FVector WindDirection;

    UPROPERTY(BlueprintReadOnly)
    float Speed;
}

class UWindWalkComponent : UActorComponent
{
    float WindForce = 200.0;
    private UWindDirectionComponent WindDirectionComp_Internal;

    UPROPERTY(BlueprintReadOnly)
    FWindWalkAnimationData AnimationData;

    UFUNCTION(BlueprintCallable)
    void SetWindIntensity(EWindIntensity WindIntensity)
    {
        GetWindDirectionComp().SetWindIntensity(WindIntensity);
    }

    bool GetIsStrongWind()
    {
        return GetWindDirectionComp().bIsStrongWind;
    }

	FVector GetWindDirection()
	{
		return GetWindDirectionComp().WindDirection;
	}

    private UWindDirectionComponent GetWindDirectionComp()
    {
        if(WindDirectionComp_Internal == nullptr)
            WindDirectionComp_Internal = UWindDirectionComponent::GetOrCreate(Game::GetMio());

        return WindDirectionComp_Internal;
    }
}