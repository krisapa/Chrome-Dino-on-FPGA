with open('smem.mem', 'w') as file:
    for i in range(1200):
        file.write('0')
        if i != 1199:
            file.write('\n')