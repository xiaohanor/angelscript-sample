// Example: Player Character with movement, health, and input handling
class APlayerCharacter : ACharacter
{
    UPROPERTY(DefaultComponent, RootComponent)
    UCapsuleComponent Capsule;
    
    UPROPERTY(DefaultComponent, Attach = Capsule)
    USkeletalMeshComponent Mesh;
    
    UPROPERTY(DefaultComponent, Attach = Capsule)
    USpringArmComponent CameraBoom;
    
    UPROPERTY(DefaultComponent, Attach = CameraBoom)
    UCameraComponent Camera;
    
    UPROPERTY(Category = "Movement")
    float WalkSpeed = 600.0f;
    
    UPROPERTY(Category = "Movement")
    float RunSpeed = 1000.0f;
    
    UPROPERTY(Category = "Health")
    float MaxHealth = 100.0f;
    
    UPROPERTY(Replicated, ReplicatedUsing = OnRep_Health)
    float Health = 100.0f;
    
    UPROPERTY()
    bool bIsRunning = false;
    
    // Input values
    FVector2D MovementInput;
    FVector2D LookInput;
    
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
        SetupInput();
    }
    
    UFUNCTION()
    void SetupInput()
    {
        APlayerController PC = Cast<APlayerController>(GetController());
        if (PC != nullptr)
        {
            UEnhancedInputComponent Input = Cast<UEnhancedInputComponent>(PC.GetPawnInputComponent());
            if (Input != nullptr)
            {
                // Bind actions
                Input.BindAction(n"Move", ETriggerEvent::Triggered, this, n"HandleMove");
                Input.BindAction(n"Look", ETriggerEvent::Triggered, this, n"HandleLook");
                Input.BindAction(n"Jump", ETriggerEvent::Started, this, n"HandleJump");
                Input.BindAction(n"Run", ETriggerEvent::Started, this, n"HandleRunStarted");
                Input.BindAction(n"Run", ETriggerEvent::Completed, this, n"HandleRunEnded");
            }
        }
    }
    
    UFUNCTION()
    void HandleMove(FInputActionValue Value)
    {
        MovementInput = Value.GetAxis2D();
        
        FVector Forward = GetActorForwardVector();
        FVector Right = GetActorRightVector();
        
        FVector Direction = Forward * MovementInput.Y + Right * MovementInput.X;
        Direction = Direction.GetSafeNormal();
        
        float Speed = bIsRunning ? RunSpeed : WalkSpeed;
        AddMovementInput(Direction, Speed);
    }
    
    UFUNCTION()
    void HandleLook(FInputActionValue Value)
    {
        LookInput = Value.GetAxis2D();
        AddControllerYawInput(LookInput.X);
        AddControllerPitchInput(LookInput.Y);
    }
    
    UFUNCTION()
    void HandleJump()
    {
        Jump();
    }
    
    UFUNCTION()
    void HandleRunStarted()
    {
        bIsRunning = true;
        GetCharacterMovement().MaxWalkSpeed = RunSpeed;
    }
    
    UFUNCTION()
    void HandleRunEnded()
    {
        bIsRunning = false;
        GetCharacterMovement().MaxWalkSpeed = WalkSpeed;
    }
    
    UFUNCTION()
    void TakeDamage(float DamageAmount, AActor DamageCauser)
    {
        if (Health <= 0)
            return;
            
        Health = FMath::Max(0.0f, Health - DamageAmount);
        
        if (Health <= 0)
        {
            OnDeath(DamageCauser);
        }
    }
    
    UFUNCTION()
    void OnRep_Health()
    {
        // Update UI or play effects
        Print("Health: " + Health + "/" + MaxHealth);
    }
    
    UFUNCTION(BlueprintEvent)
    void OnDeath(AActor Killer);
    
    UFUNCTION(BlueprintOverride)
    void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
    {
        Super::GetLifetimeReplicatedProps(OutLifetimeProps);
        DOREPLIFETIME(APlayerCharacter, Health);
    }
}
